split_task_list <- function(
  tsk_feateng_flatlist,
  split_indices
) {
  # Splitting into train and test
  .train_tsk_list <- tsk_feateng_flatlist %>%
    map(\(tsk) {
      tsk$clone(deep = TRUE)$filter(seq(1, split_indices$train, by = 1))
    })

  .test_tsk_list <- tsk_feateng_flatlist %>%
    map(\(tsk) {
      tsk$clone(deep = TRUE)$filter(seq(1, split_indices$test, by = 1))
    })

  map2(.train_tsk_list, .test_tsk_list, \(train_tsk, test_tsk) {
    info_msg(paste0(
      "Task `",
      train_tsk$id,
      "` has ",
      train_tsk$nrow,
      " train rows and ",
      test_tsk$nrow - train_tsk$nrow,
      " test rows"
    ))
  })

  list(
    train_tsk_list = .train_tsk_list,
    test_tsk_list = .test_tsk_list
  )
}
