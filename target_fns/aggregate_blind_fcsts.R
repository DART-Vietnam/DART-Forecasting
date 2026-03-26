aggregate_blind_fcsts <- function(blind_fcst_flatlist) {
  blind_fcst_flatlist %>% list_rbind()
}
