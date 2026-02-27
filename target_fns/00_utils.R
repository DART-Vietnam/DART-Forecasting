info_msg <- function(msg, ...) {
  msg <- paste0(msg, ...)

  cli::cli_inform(
    sprintf("[%s] (INFO) {.strong %s}", Sys.time(), msg)
  )
}

warn_msg <- function(msg, ...) {
  msg <- paste0(msg, ...)

  cli::cli_warn(
    sprintf("[%s] (WARN) {.strong %s}", Sys.time(), msg)
  )
}
