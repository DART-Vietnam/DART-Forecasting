normalise_isodates <- function(tbl_df) {
  tbl_df %>%
    mutate(
      isoyear = isoyear(date),
      isoweek = isoweek(date),
      .after = date
    ) %>%
    mutate(
      .isoyear = as.integer(ifelse(isoweek == 53, isoyear + 1, isoyear)),
      .isoweek = as.integer(ifelse(isoweek == 53, 1, isoweek)),
      isoyear = .isoyear,
      isoweek = .isoweek
    ) %>%
    group_by(region, isoyear, isoweek) %>%
    summarise(
      date = min(date),
      # weather variables that work better with mean
      across(
        starts_with(
          c(
            "t2m",
            "r",
            "q",
            "mn2t24",
            "mx2t24",
            "mnr24",
            "mxr24",
            "mnq24",
            "mxq24",
            "spi",
            "spei"
          )
        ),
        ~ mean(.x, na.rm = TRUE)
      ),
      # weather variables that work better with sum
      across(starts_with(c("tp", "hb")), ~ sum(.x, na.rm = TRUE))
    ) %>%
    ungroup() %>%
    arrange(region, isoyear, isoweek) %>%
    mutate(
      .datestr = sprintf("%d-W%02d-1", isoyear, isoweek),
      date = ISOweek2date(.datestr)
    ) %>%
    select(-any_of(c(".isoyear", ".isoweek", ".datestr")))
}

read_era5_data <- function(fpath) {
  .raw_era5_dat <- read_ncdf(fpath, make_units = FALSE) %>%
    suppressWarnings()

  .raw_era5_dat %>%
    as_tibble() %>%
    mutate(region = as.character(region)) %>%
    mutate(date = as.Date(time), .after = region) %>%
    filter(startsWith(as.character(region), "VNM.25")) %>%
    select(-time) %>%
    normalise_isodates()
}

read_wrf_ds_data <- function(fpath) {
  .raw_wrf_ds_dat <- read_ncdf(fpath, make_units = FALSE) %>%
    suppressWarnings()
  .raw_wrf_ds_dat <- setNames(.raw_wrf_ds_dat, "tp_ds")

  .raw_wrf_ds_dat %>%
    as_tibble() %>%
    mutate(
      region = as.character(region),
      date = as.Date(time),
      tp_ds = tp_ds / 1000
    ) %>%
    filter(startsWith(as.character(region), "VNM.25")) %>%
    normalise_isodates()
}

load_weather_data <- function(
  fpaths,
  configs = list(
    region = "VNM",
    admin_level = 1,
    met_data = list(
      load_era = TRUE,
      load_wrf_ds = TRUE,
    )
  )
) {
  .files <- list.files(fpaths, full.names = TRUE)
  .metrics <- c("era5", "wrf_downscale.precip")
  .patterns <- sprintf(
    "%s-%d-.+%s(.weekly)?.nc",
    configs$region,
    configs$admin_level,
    .metrics
  )

  .era5_fpath <- .files[[grep(.patterns[1], .files)]]
  .era5_weather_dat <- if (configs$met_data$load_era) {
    read_era5_data(.era5_fpath)
  } else {
    NULL
  }

  .wrf_ds_fpath <- .files[[grep(.patterns[2], .files)]]
  .ds_weather_dat <- if (configs$met_data$load_wrf_ds) {
    read_wrf_ds_data(.wrf_ds_fpath)
  } else {
    NULL
  }

  template_tbl <- tibble(region = character(), date = as.Date(0))

  full_join(
    .era5_weather_dat %||% template_tbl,
    .ds_weather_dat %||% template_tbl,
    by = join_by(region, date)
  )
}
