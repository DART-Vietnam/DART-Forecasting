library(targets)

tar_config_set(
  store = "container_targets",
  project = "dart-forecasting-container"
)
tar_path_store()

# tar_poll()
tar_watch()
