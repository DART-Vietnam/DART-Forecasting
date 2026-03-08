blind_fcst <- function(trained_tuned_lrner, newdata_tbl) {
  .trained_tuned_lrner <- trained_tuned_lrner[[1]]
  .newdata_tbl <- newdata_tbl[[1]]

  .trained_tuned_lrner$predict_newdata(newdata = .newdata_tbl)
}
