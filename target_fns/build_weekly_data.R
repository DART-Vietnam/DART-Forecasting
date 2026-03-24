build_weekly_data <- function(
  inc_dat,
  met_dat,
  .join_cols = c("region", "date"),
  .crop_ts = TRUE
) {
  .inc_full_dates <- inc_dat %>% drop_na() %>% pull(date)
  .met_full_dates <- met_dat %>% drop_na() %>% pull(date)
  left_date_lim <- max(min(.met_full_dates), min(.inc_full_dates))
  right_date_lim <- min(max(.met_full_dates), max(.inc_full_dates))

  if (.crop_ts) {
    info_msg(
      "Cropping time series to: ",
      left_date_lim,
      " - ",
      right_date_lim
    )

    inc_dat <- inc_dat %>% filter(between(date, left_date_lim, right_date_lim))
    met_dat <- met_dat %>% filter(between(date, left_date_lim, right_date_lim))
  }

  full_dat <- full_join(inc_dat, met_dat, by = .join_cols)
  if (anyNA(full_dat)) {
    warn_msg(
      "NAs found in incidence and/or meteorological data. Try setting `.crop_ts = TRUE`"
    )
  }

  full_dat
}
