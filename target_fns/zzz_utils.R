info_msg <- function(msg, ...) {
  msg <- paste0(msg, ...)

  cli::cli_inform(
    sprintf("[%s] (INFO) {.strong %s}", Sys.time(), msg)
  )
}

warn_msg <- function(msg, ...) {
  msg <- paste0(msg, ...)

  cli::cli_warn(
    sprintf("[%s] (WARN) {.strong %s}", Sys.time(), msg)
  )
}

calculate_lags <- function(df, vars, lags, id_cols, .keep_vars = FALSE) {
  if (.keep_vars) {
    id_cols <- c(id_cols, vars)
  }

  map_lag <- map(lags, ~ partial(lag, n = .x))
  cnames <- expand_grid(v = vars, l = lags) %>%
    mutate(glue = str_glue("{v}_lag{l}")) %>%
    pull(glue)

  map(vars, \(var) {
    mutate(
      df,
      across(
        .cols = all_of({{ var }}),
        .fns = map_lag,
        .names = "{.col}_lag{lags}"
      )
    ) %>%
      select(all_of(id_cols), any_of(cnames))
  }) %>%
    reduce(left_join, by = id_cols)
}

calculate_cum_sums <- function(lagged_df, vars, start, lengths, id_cols) {
  if (start < 1) {
    stop("`start` has to be larger than 0")
  }
  if (min(lengths) < 2) {
    stop("`lengths` has to be larger than 1")
  }

  var_winlength_grid <- expand_grid(vars, lengths)

  map2(
    var_winlength_grid$vars,
    var_winlength_grid$lengths,
    \(cur_var, cur_len) {
      start_lag <- start
      end_lag <- start + cur_len - 1

      lagged_df %>%
        pivot_longer(
          cols = -c(date, region),
          names_pattern = "(\\w+)_lag(\\d+)",
          names_to = c("var", "lag_amt"),
          values_to = "value"
        ) %>%
        mutate(lag_amt = as.integer(lag_amt)) %>%
        filter(between(lag_amt, start_lag, end_lag)) %>%
        group_by(date, region) %>%
        select(-lag_amt) %>%
        summarise(value = sum(value), .groups = "drop") %>%
        rename("{cur_var}_cumsum_{start_lag}_{end_lag}" := value)
    }
  ) %>%
    reduce(left_join, by = id_cols)
}

recomb_into_flatlist <- function(
  branched_list_obj,
  obj_listname,
  id_listname = "id"
) {
  .actual_objs <- map(branched_list_obj, \(list_obj) list_obj[[obj_listname]])
  .actual_ids <- map(branched_list_obj, \(list_obj) list_obj[[id_listname]])

  .named_objs <- set_names(.actual_objs, .actual_ids)
  .named_objs
}
