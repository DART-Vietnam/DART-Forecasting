load_tuned_lrners_flatlist <- function(
  folder_path,
  configs = list(
    region = "VNM",
    admin_level = 1,
    learner_id = "regr.ranger",
    met_dat_included = TRUE
  )
) {
  if (!(configs$learner_id %in% c("regr.ranger", "regr.xgboost"))) {
    stop(paste0("`", configs$learner_id, "` not supported"))
  }
  .vars <- if (configs$met_dat_included) "allVars" else "incVars"

  .files <- list.files("data/mlr3_objs", full.names = TRUE)
  .pattern <- sprintf(
    "%s-%d-%s-%s-tuned_lrner_flatlist.qs2",
    configs$region,
    configs$admin_level,
    configs$learner_id,
    .vars
  )

  lrner_fpath <- .files %>% str_subset(.pattern)

  if (is_empty(lrner_fpath)) {
    stop(paste0(
      "`",
      configs$learner_id,
      "` file not found. Expecting: ",
      .pattern
    ))
  }

  qs_read(lrner_fpath)
}
