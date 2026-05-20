library(targets)

Sys.setenv(TOML_CONF_FPATH = "targets_config.toml")

tar_config_set(
  store = "container_targets"
)
tar_path_store()

# tar_poll()
tar_watch()
