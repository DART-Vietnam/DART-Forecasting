blind_fcst_w_agaci <- function(
  trained_tuned_lrner,
  newdata_tbl,
  calibrated_agaci_obj
) {
  .wa <- names(newdata_tbl) %>% str_extract("\\d+") %>% as.numeric()
  .trained_tuned_lrner <- trained_tuned_lrner[[1]]
  .newdata_tbl <- newdata_tbl[[1]]
  .calibrated_agaci_obj <- calibrated_agaci_obj[[1]]

  .newdata_pred_tbl <- .trained_tuned_lrner$predict_newdata(
    newdata = .newdata_tbl
  ) %>%
    as.data.table()

  .newdata_pis <- map(.calibrated_agaci_obj, \(pi_obj) {
    predict(pi_obj, log1p(.newdata_pred_tbl$response)) %>%
      expm1() %>%
      as.list() %>%
      as.data.table()
  }) %>%
    imap(\(agaci_pi_row, pi_name) {
      tibble(
        response = .newdata_pred_tbl$response,
        interval = str_extract(pi_name, "0.\\d+") %>% as.numeric(),
        lower = agaci_pi_row[[1, 1]], # first col
        upper = agaci_pi_row[[1, 2]], # second col
      )
    }) %>%
    list_rbind() %>%
    mutate(date = as.Date(.newdata_tbl$date_num + (7 * (.wa - 1))))

  .newdata_pis
}
