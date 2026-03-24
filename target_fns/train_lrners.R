train_lrners <- function(named_lrner, named_tsk) {
  .id <- names(named_lrner)
  .lrner <- named_lrner[[1]]
  .tsk <- named_tsk[[1]]

  .lrner$train(.tsk)

  list(
    id = .id,
    trained_lrner = .lrner
  )
}
