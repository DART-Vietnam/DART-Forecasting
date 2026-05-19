library(autometric)
library(crew)
library(targets)
library(cli)
suppressPackageStartupMessages(library(tidyverse))

# Load mlr3 stuff and ML learners here
# so that qs2 deserialisaion can happen correctly
# when loading mlr3 learners from qs2 files
library(mlr3)
library(mlr3pipelines)
library(mlr3learners)
library(ranger)

# load envs (from docker compose file)
## crew workers for branch parallelisation
.env_crew_workers <- as.integer(Sys.getenv("CREW_WORKERS"))
.crew_workers <- if (is.na(.env_crew_workers)) {
  4L
} else {
  .env_crew_workers
}

## load TOML container run-time configs
.toml_fpath <- Sys.getenv("TOML_CONF_FPATH")
if (.toml_fpath == "") {
  cli_abort("`TOML_CONF_FPATH` env var must be supplied")
}

log_dir <- "_targets/logs/"

# setup crew workers
.local_crew_controller <- crew_controller_local(
  workers = .crew_workers,
  crashes_max = 0L,
  options_metrics = crew_options_metrics(
    path = paste0(log_dir, "local_crew_workers/metrics"),
    seconds_interval = 1L
  ),
  options_local = crew_options_local(
    log_directory = paste0(log_dir, "local_crew_workers/logs")
  )
)

# setup targets options
tar_source("target_fns")
tar_option_set(
  packages = c("tidyverse", "data.table"),
  format = "qs",
  seed = 764,
  controller = .local_crew_controller,
  retrieval = "worker",
  storage = "worker"
)

# setup `autometric` logging for trunk process
if (tar_active()) {
  log_start(
    path = paste0(log_dir, "main_process.txt"),
    seconds = 1
  )
}

# some checks
toml_conf <- toml::read_toml(.toml_fpath)
if (.crew_workers != toml_conf$forecast$max_horizon) {
  cli_warn(paste0(
    "There are ",
    .crew_workers,
    " parallel `targets` workers, while the max_horizon is ",
    toml_conf$forecast$max_horizon,
    "\n",
    "For optimal parallelisation performance, consider these two values to be the same, i.e. 1 horizon per parallel worker"
  ))
}
