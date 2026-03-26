full_test_resampling <- function(
  test_tsk,
  tuned_lrner,
  train_test_split_indices,
  id,
  blind_fcst_start_date = NULL
) {
  # If doing blind forecasting: Cut the time series at the end of that date
  # If not: Cut the time series at the end of the training set (80% time series)
  .rowid_cut <- if (!is.null(blind_fcst_start_date)) {
    test_tsk$data() %>%
      rowid_to_column() %>%
      mutate(date = as.Date(date_num)) %>%
      get_row_closest_date(blind_fcst_start_date) %>%
      pull(rowid)
  } else {
    train_test_split_indices$train
  }

  # Generate resampling sets based on the Cut above
  .resampling <- rsmp(
    "fcst.cv",
    horizon = 1,
    folds = train_test_split_indices$test - .rowid_cut,
    window_size = .rowid_cut,
    fixed_window = FALSE
  )

  # If doing blind forecasting: Filter the testing set task based on the Cut above
  if (!is.null(blind_fcst_start_date)) {
    .rowid_blind_fcst <- test_tsk$data() %>%
      rowid_to_column() %>%
      mutate(date = as.Date(date_num)) %>%
      get_row_closest_date(blind_fcst_start_date + (7 * fh)) %>%
      pull(rowid)

    test_tsk$filter(c(seq(1:.rowid_cut), .rowid_blind_fcst))
  }

  # Instantiate the resampling on the task and do the resampling
  .resampling$instantiate(test_tsk)
  rsmp_obj <- resample(
    task = test_tsk,
    learner = tuned_lrner,
    resampling = .resampling
  )

  # Get the resampling predictions
  rsmp_preds <- rsmp_obj$prediction() %>%
    as.data.table() %>%
    arrange(row_ids)

  # If doing blind forecasting: Correctly reassign the row id of forecasted date
  if (!is.null(blind_fcst_start_date)) {
    rsmp_preds <- rsmp_preds %>%
      mutate(
        row_ids = case_when(
          row_ids == max(row_ids) ~ .rowid_blind_fcst,
          .default = row_ids
        )
      )
  }

  list(
    id = id,
    full_test_preds = rsmp_preds
  )
}
