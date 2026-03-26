calibrate_agaci_obj <- function(
  agaci_obj,
  full_train_pred_obj,
  ptrain_calib_split_indices
) {
  calibration_df <- full_train_pred_obj[[1]] %>%
    as.data.table() %>%
    arrange(row_ids) %>%
    tail(ptrain_calib_split_indices$test - ptrain_calib_split_indices$train) %>%
    mutate(across(
      c(truth, response),
      ~ case_when(.x < 0 ~ NA, .default = .x)
    )) %>% # mutate negative forecasts to NA
    mutate(across(c(truth, response), log1p))

  if (
    calibration_df %>%
      lapply(\(x) {
        is.nan(x) | is.na(x)
      }) %>%
      list_c() %>%
      any()
  ) {
    calibration_df <- calibration_df %>%
      mutate(response = na_interpolation(response))
    warn_msg(
      "NaNs/NAs found in train test predictions while calibrating AgACI. These values are linear-interpolated"
    )
  }

  .updated_agaci_obj <- map(agaci_obj$agaci_obj, \(expert) {
    ## final `map()` goes through the PIs "layer"
    updated_expert <- expert %>%
      update(
        newY = calibration_df$truth,
        newpredictions = calibration_df$response,
        training = FALSE
      )

    updated_expert
  })

  list(
    id = agaci_obj$id,
    updated_agaci_obj = .updated_agaci_obj
  )
}
