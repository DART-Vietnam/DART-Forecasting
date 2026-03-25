get_full_dates <- function(dat = NULL, colname = "date") {
  if (is.null(dat)) {
    return(NULL)
  }

  dat %>% drop_na() %>% pull(colname)
}

filter_date_inbetween <- function(
  dat = NULL,
  left_date_lim,
  right_date_lim,
  colname = "date"
) {
  if (is.null(dat)) {
    return(NULL)
  }
  dat %>%
    filter(between(
      !!sym(colname),
      as.Date(left_date_lim),
      as.Date(right_date_lim)
    ))
}

build_weekly_data <- function(
  inc_dat,
  met_dat = NULL,
  .join_cols = c("region", "date"),
  .crop_ts = TRUE
) {
  .inc_full_dates <- get_full_dates(inc_dat)
  .met_full_dates <- get_full_dates(met_dat)
  # if not met dates then default to inc dates
  left_date_lim <- max(
    min(.met_full_dates %||% .inc_full_dates),
    min(.inc_full_dates)
  )
  right_date_lim <- min(
    max(.met_full_dates %||% .inc_full_dates),
    max(.inc_full_dates)
  )

  if (.crop_ts) {
    info_msg(
      "Cropping time series to: ",
      left_date_lim,
      " - ",
      right_date_lim
    )

    filtered_inc_dat <- filter_date_inbetween(
      inc_dat,
      left_date_lim,
      right_date_lim
    )
    filtered_met_dat <- filter_date_inbetween(
      met_dat,
      left_date_lim,
      right_date_lim
    ) %||%
      inc_dat %>%
      head(0) %>%
      select(-n)
  }

  full_dat <- full_join(filtered_inc_dat, filtered_met_dat, by = .join_cols)
  if (anyNA(full_dat) && !is.null(met_dat)) {
    warn_msg(
      "NAs found in incidence and/or meteorological data. Try setting `.crop_ts = TRUE`"
    )
  }

  full_dat
}
