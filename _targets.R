library(autometric)
library(crew)
library(targets)
suppressPackageStartupMessages(library(tidyverse))

# load envs (from docker compose file)
## crew workers for branch parallelisation
.env_crew_workers <- as.numeric(Sys.getenv("CREW_WORKERS"))
.crew_workers <- if (is.na(.env_crew_workers)) {
  4L
} else {
  .env_crew_workers
}

## load TOML container run-time configs
.toml_fpath <- Sys.getenv("TOML_CONF_FPATH")
if (.toml_fpath == "") {
  stop("`TOML_CONF_FPATH` env var must be supplied")
}

log_dir <- "_targets/logs/"

# setup crew workers
.local_crew_controller <- crew_controller_local(
  workers = .crew_workers,
  options_metrics = crew_options_metrics(
    path = paste0(log_dir, "local_crew_workers"),
    seconds_interval = 1
  )
)

# setup targets options
tar_source("target_fns")
tar_option_set(
  packages = c("tidyverse"),
  format = "qs",
  seed = 764,
  controller = .local_crew_controller
)

# setup `autometric` logging for trunk process
if (tar_active()) {
  log_start(
    path = paste0(log_dir, "target_trunk.txt"),
    seconds = 1
  )
}

list(
  #
  # Load run-time config
  tar_target(toml_conf, read_toml(.toml_fpath)),
  #
  # Load incidence data
  tar_target(
    incidence_data,
    read_incidence_data(toml_conf$data$paths$incidence)
  ),
  tar_target(weather_data, read_weather_data(toml_conf$data$paths$weather))
)
