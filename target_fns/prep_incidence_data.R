.gid_namemap <- tribble(
  ~csv_cname , ~gid          ,
  "bc"       , "VNM.25.1_1"  ,
  "bta"      , "VNM.25.2_1"  ,
  "bt"       , "VNM.25.3_1"  ,
  "cg"       , "VNM.25.4_1"  ,
  "cc"       , "VNM.25.5_1"  ,
  "gv"       , "VNM.25.6_1"  ,
  "hm"       , "VNM.25.7_1"  ,
  "nb"       , "VNM.25.8_1"  ,
  "pn"       , "VNM.25.9_1"  ,
  "q10"      , "VNM.25.10_1" ,
  "q11"      , "VNM.25.11_1" ,
  "q12"      , "VNM.25.12_1" ,
  "q1"       , "VNM.25.13_1" ,
  "q2"       , "VNM.25.14_1" ,
  "q3"       , "VNM.25.15_1" ,
  "q4"       , "VNM.25.16_1" ,
  "q5"       , "VNM.25.17_1" ,
  "q6"       , "VNM.25.18_1" ,
  "q7"       , "VNM.25.19_1" ,
  "q8"       , "VNM.25.20_1" ,
  "q9"       , "VNM.25.21_1" ,
  "tb"       , "VNM.25.22_1" ,
  "tp"       , "VNM.25.23_1" ,
  "td"       , "VNM.25.24_1" ,
  "thanhpho" , "VNM.25_1"    ,
)

prep_incidence_data <- function(raw_dat, admin_level) {
  .norm_dat <- raw_dat %>%
    # normalise colnames to english
    rename(isoyear = nam, isoweek = tuan) %>%
    # roll w53 into w1 into next year (HCDC req)
    mutate(
      .isoyear = as.integer(ifelse(isoweek == 53, isoyear + 1, isoyear)),
      .isoweek = as.integer(ifelse(isoweek == 53, 1, isoweek)),
      isoyear = .isoyear,
      isoweek = .isoweek
    ) %>%
    select(-c(.isoyear, .isoweek)) %>%
    pivot_longer(cols = -c(isoyear, isoweek)) %>%
    # add GID1 and GID2 values
    mutate(
      gid = recode_values(
        name,
        from = .gid_namemap$csv_cname,
        to = .gid_namemap$gid
      ),
      gidlvl = as.character(str_count(gid, "\\."))
    ) %>%
    select(-name) %>%
    # get date from isoyear and isoweek
    mutate(
      datestr = sprintf("%d-W%02d-1", isoyear, isoweek),
      date = ISOweek2date(datestr)
    ) %>%
    group_by(isoyear, isoweek, gid) %>%
    summarise(
      date = min(date),
      value = sum(value),
      gidlvl = unique(gidlvl),
      .groups = "drop"
    ) %>%
    filter(gidlvl == admin_level) %>%
    select(gid, date, value) %>%
    rename(region = gid, n = value)

  .norm_dat
}
