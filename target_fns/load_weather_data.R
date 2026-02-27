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
      date = as.Date(date),
      tp_ds = tp_ds / 1000
    ) %>%
    filter(startsWith(as.character(region), "VNM.25")) %>%
    normalise_isodates()
}

load_weather_data <- function(fpaths) {
  .era5_fpath <- fpaths[[grep("era5", fpaths)]]
  .era5_weather_dat <- read_era5_data(.era5_fpath)

  .wrf_ds_fpath <- fpaths[[grep("precip", fpaths)]]
  .ds_weather_dat <- read_wrf_ds_data(.wrf_ds_fpath)

  .era5_weather_dat %>%
    full_join(.ds_weather_dat)
}
