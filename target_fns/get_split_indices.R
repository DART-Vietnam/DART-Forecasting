get_split_indices <- function(
  task_obj,
  percentage = NULL,
  train_cut_date = NULL
) {
  if (!xor(is.null(percentage), is.null(train_cut_date))) {
    stop(
      "Either `percentage` or `train_cut_date` needs to be supplied and exclusive"
    )
  }
  if (!inherits(percentage, "numeric") || percentage < 0 || percentage > 1) {
    stop("`percentage` needs to be a number between 0 and 1")
  }
  .nrow <- task_obj$nrow

  .rowid_train_cut <- if (!is.null(train_cut_date)) {
    task_obj$data() %>%
      rowid_to_column() %>%
      mutate(date = as.Date(date_num), .after = date_num) %>%
      get_row_closest_date(target_date = train_cut_date) %>%
      pull(rowid)
  } else {
    round(.nrow * percentage)
  }

  list(
    train = .rowid_train_cut,
    test = .nrow
  )
}
