library(autometric)
library(crew)
library(targets)

# load envs (from docker compose file)
## crew workers for branch parallelisation
.env_crew_workers <- as.numeric(Sys.getenv("CREW_WORKERS"))
.crew_workers <- if (is.na(.env_crew_workers)) {
  4L
} else {
  .env_crew_workers
}

## fpath for new incidence data
.new_incidence_fpath <- Sys.getenv("NEW_INC_FPATH")
if (.new_incidence_fpath == "") {
  stop("`NEW_INC_FPATH` env var must be supplied")
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
  tar_target(new_incidence_data, read_new_dat(.new_incidence_fpath))
)
