aggregate_blind_fcsts <- function(blind_fcst_flatlist, blind_fcst_orig_date) {
  fcst_dates <- blind_fcst_orig_date + (7 * (1:12))

  fcst_resps <- map(blind_fcst_flatlist, \(mlr_pred_obj) {
    mlr_pred_obj$response
  })

  data.table(
    date = fcst_dates,
    response = unlist(fcst_resps)
  )
}
