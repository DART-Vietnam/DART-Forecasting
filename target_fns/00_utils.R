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

  map(
    vars,
    \(cur_var) {
      df %>%
        mutate(across(
          .cols = all_of({{ cur_var }}),
          .fns = map_lag,
          .names = "{.col}_lag{lags}"
        )) %>%
        select(all_of(id_cols), any_of(cnames))
    }
  ) %>%
    reduce(left_join, by = id_cols)
}

calculate_cum_sums <- function(df, vars, start, lengths, id_cols) {
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
      total_lags <- seq(start, start + cur_len - 1)
      lagged_df <- calculate_lags(df, cur_var, total_lags, id_cols)
      cumsum_df <- lagged_df %>%
        mutate(
          "{cur_var}_cumsum_{start}_{start+cur_len-1}" := rowSums(pick(
            everything(),
            -date
          )),
          .before = everything()
        ) %>%
        select(all_of(id_cols), 1)

      cumsum_df
    }
  ) %>%
    reduce(left_join, by = id_cols)
}
