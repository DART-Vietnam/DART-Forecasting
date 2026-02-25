#!/usr/bin/env Rscript

library(targets)

# Run targets pipeline
tar_res <- tar_make(script = "./_targets.R")

## Debug with
# tar_make(callr_function = NULL, use_crew = FALSE, as_job = FALSE)
