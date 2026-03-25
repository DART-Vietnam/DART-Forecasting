#!/usr/bin/env Rscript

library(targets)

tar_config_set(script = "./_targets.R")

# Run targets pipeline
tar_res <- tar_make(
  ## Debug with
  # callr_function = NULL,
  # use_crew = FALSE,
  # as_job = FALSE
)
