load_tuned_lrners_flatlist <- function(lrner_id) {
  if (!(lrner_id %in% c("regr.ranger", "regr.xgboost"))) {
    stop(paste0("`", lrner_id, "` not supported"))
  }

  lrner_fpath <- list.files("data/mlr3_objs", full.names = TRUE) %>%
    str_subset(lrner_id)

  if (is_empty(lrner_fpath)) {
    stop(paste0("`", lrner_id, "` file not found"))
  }

  qs_read(lrner_fpath)
}
