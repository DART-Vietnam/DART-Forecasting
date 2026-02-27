load_incidence_data <- function(fpath) {
  .raw_dat <- read_csv(fpath)

  .norm_dat <- .raw_dat %>%
    select(nam, tuan, thanhpho) %>%
    # normalise colnames to english
    rename(isoyear = nam, isoweek = tuan, n = thanhpho) %>%
    # roll w53 into w1 into next year (HCDC req)
    mutate(
      .isoyear = as.integer(ifelse(isoweek == 53, isoyear + 1, isoyear)),
      .isoweek = as.integer(ifelse(isoweek == 53, 1, isoweek)),
      isoyear = .isoyear,
      isoweek = .isoweek
    ) %>%
    # get date from isoyear and isoweek
    mutate(
      datestr = sprintf("%d-W%02d-1", isoyear, isoweek),
      date = ISOweek2date(datestr)
    ) %>%
    select(isoyear, isoweek, date, n) %>%
    group_by(isoyear, isoweek) %>%
    summarise(date = min(date), n = sum(n)) %>%
    ungroup() %>%
    mutate(region = "VNM.25_1") %>%
    select(region, date, n)

  .norm_dat
}
