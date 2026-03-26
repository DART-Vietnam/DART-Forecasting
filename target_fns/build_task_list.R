fcst_task_builder <- function(
  dtbl,
  horizon,
  select_vars = character(),
  lagging = TRUE,
  cumsum = TRUE,
  lag_vars = character(),
  cumsum_vars = character(),
  join_idcol = c("date"),
  .padding = FALSE,
  .pad_till = FALSE
) {
  if (lagging == TRUE && length(lag_vars) == 0) {
    stop("Needs to populate `lag_vars` because `lagging==TRUE`")
  }
  if (cumsum == TRUE && length(cumsum_vars) == 0) {
    stop("Needs to populate `cumsum_vars` because `cumsum==TRUE`")
  }
  if (length(horizon) != 1 || horizon < 1) {
    stop("`horizon` must a single positive number")
  }
  if (.padding == TRUE && !is.Date(.pad_till)) {
    stop("`.pad_till` needs to be a date string when `.padding` is TRUE")
  }

  # padding for blind forecasting
  if (.padding == TRUE) {
    dtbl <- dtbl %>%
      map(\(tbl) {
        start_date <- tbl %>% tail(1) %>% pull(date)

        tbl %>%
          bind_rows(
            tibble(
              date = seq.Date(start_date + 7, .pad_till, by = "7 days"),
              n = -98765L
            )
          )
      })
  }

  info_msg(paste0("Generating lags for ", horizon, "-week-ahead"))
  lag_dtbl <- if (lagging == TRUE) {
    calculate_lags(
      df = dtbl,
      vars = lag_vars,
      lags = seq(horizon, 12 + horizon - 1),
      id_cols = join_idcol
    )
  } else {
    dtbl
  }

  info_msg(paste0("Generating cumumlative sums for ", horizon, "-week-ahead"))
  cumsum_dtbl <- if (cumsum == TRUE) {
    calculate_cum_sums(
      lagged_df = lag_dtbl,
      vars = cumsum_vars,
      start = horizon,
      lengths = 2:12,
      id_cols = join_idcol
    )
  } else {
    dtbl
  }

  select_vars <- unique(c(
    select_vars,
    colnames(lag_dtbl),
    colnames(cumsum_dtbl)
  ))

  joined_dtbl <- dtbl %>%
    left_join(lag_dtbl, by = join_idcol) %>%
    left_join(cumsum_dtbl, by = join_idcol) %>%
    # remove impossible incidence values, likely resulted from date padding
    mutate(across(
      c(starts_with("n"), -n),
      ~ case_when(.x < 0 ~ NA, .default = .x)
    )) %>%
    select(all_of(c(join_idcol, select_vars))) %>%
    # drop the first (max lag amount) + (max cumsum window) rows
    tail(-(12 + 12))

  # count the number of periods to determine GID level
  gid_lvl <- switch(
    str_count(joined_dtbl$region[[1]], "\\."),
    "2" = 1,
    "3" = 2,
    "unknown"
  )
  iso3 <- str_extract(joined_dtbl$region[[1]], "\\w{3}")

  info_msg(paste0("Generating tasks for ", horizon, "-week-ahead"))
  fcst_tsk <- joined_dtbl %>%
    mutate(date_num = as.numeric(date), region = as.factor(region)) %>%
    as_task_fcst(
      target = "n",
      order = "date",
      key = "region",
      freq = "1 week",
      id = sprintf("%s-%d_fh-%d_wa", iso3, gid_lvl, horizon)
    )

  fcst_tsk
}

build_task_list <- function(
  weekly_data,
  max_horizon,
  lag_cumsum_vars = c("n"),
  join_idcol = c("date")
) {
  forecast_horizons <- seq(1, as.integer(max_horizon), by = 1)

  tsk_feateng_list <- map(
    forecast_horizons,
    \(fh) {
      fcst_task_builder(
        weekly_data,
        horizon = fh,
        select_vars = c("n"),
        lag_vars = lag_cumsum_vars,
        cumsum_vars = lag_cumsum_vars,
        join_idcol = join_idcol
      )
    }
  ) %>%
    setNames(
      paste0("fh", forecast_horizons, "wa")
    )

  list_flatten(tsk_feateng_list, name_spec = "{outer}_{inner}")
}
