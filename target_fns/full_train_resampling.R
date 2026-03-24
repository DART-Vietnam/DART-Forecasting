full_train_resampling <- function(
  train_tsk,
  tuned_lrner,
  train_test_split_indices,
  id
) {
  tuned_lrner <- tuned_lrner[[1]]
  .lrner_id <- tuned_lrner$base_learner()$id

  min_obs <- if (.lrner_id == "regr.ranger") {
    ## make sure `ranger` has enough samples for sampling
    ceiling(
      1 / tuned_lrner$pipeops_param_set$regr.ranger$values$sample.fraction
    )
  } else if (.lrner_id == "regr.xgboost") {
    ## make sure `xgboost` has enough samples for subsampling
    ceiling(1 / tuned_lrner$pipeops_param_set$regr.xgboost$values$subsample)
  } else {
    2
  }

  resampling <- rsmp(
    "fcst.cv",
    horizon = 1,
    folds = train_test_split_indices$train - min_obs,
    window_size = min_obs,
    fixed_window = FALSE
  )
  resampling$instantiate(train_tsk)

  rsmp_obj <- resample(
    task = train_tsk,
    learner = tuned_lrner,
    resampling = resampling
  )
  rsmp_preds <- rsmp_obj$prediction()

  list(
    id = id,
    full_train_preds = rsmp_preds
  )
}
