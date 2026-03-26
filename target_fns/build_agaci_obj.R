build_agaci_obj <- function(
  full_train_preds_obj,
  ptrain_calib_split_indices,
  p_ints
) {
  proper_train_pred_df <- full_train_preds_obj[[1]] %>%
    as.data.table() %>%
    arrange(row_ids) %>%
    head(ptrain_calib_split_indices$train) %>%
    mutate(across(c(truth, response), log1p))

  .agaci_obj <- map(p_ints, \(cur_int) {
    agaci_obj <- aci(
      Y = proper_train_pred_df$truth,
      predictions = proper_train_pred_df$response,
      alpha = cur_int,
      method = "AgACI",
      training = TRUE
    )
  }) %>%
    setNames(paste0("pi", p_ints))

  list(
    id = names(full_train_preds_obj),
    agaci_obj = .agaci_obj
  )
}
