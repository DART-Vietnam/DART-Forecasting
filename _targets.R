library(autometric)
library(crew)
library(targets)
suppressPackageStartupMessages(library(tidyverse))

# Load mlr3 stuff and ML learners here
# so that qs2 deserialisaion can happen correctly
# when loading mlr3 learners from qs2 files
library(mlr3)
library(mlr3pipelines)
library(mlr3learners) #
library(ranger)

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
  packages = c("tidyverse", "data.table"),
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
  tar_target(run_conf_fpath, .toml_fpath, format = "file"),
  tar_target(run_conf, read_toml(run_conf_fpath), packages = c("toml")),
  #
  # Load input data
  tar_target(
    incidence_data,
    load_incidence_data(run_conf$data$paths$incidence),
    packages = c(tar_option_get("packages"), "ISOweek")
  ),
  tar_target(
    weather_data,
    load_weather_data(run_conf$data$paths$weather),
    packages = c(tar_option_get("packages"), "stars", "ISOweek")
  ),
  tar_target(
    weekly_data_list,
    build_weekly_data_list(incidence_data, weather_data)
  ),
  #
  # Build feature-engineered flatlist
  tar_target(
    tsk_feateng_flatlist,
    build_task_list(weekly_data_list, run_conf$forecast$max_horizon),
    packages = c(tar_option_get("packages"), "mlr3forecast")
  ),
  #
  # Load tuned learners
  tar_target(
    tuned_lrners_flatlist,
    load_tuned_lrners_flatlist(run_conf$forecast$learner_id),
    packages = c(tar_option_get("packages"), "qs2")
  ),
  #
  # Train the tuned learners
  tar_target(
    trained_tuned_lrners,
    train_lrners(tuned_lrners_flatlist, tsk_feateng_flatlist),
    pattern = map(tuned_lrners_flatlist, tsk_feateng_flatlist),
    iteration = "list"
  )
)
