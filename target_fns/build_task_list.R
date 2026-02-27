fcst_task_builder <- function(
  tbl_list,
  horizon,
  select_vars = character(),
  lagging = TRUE,
  cumsum = TRUE,
  lag_vars = character(),
  cumsum_vars = character(),
  join_idcol = "date",
  .padding = FALSE,
  .pad_till = FALSE
) {
  if (lagging == TRUE && length(lag_vars) == 0) {
    stop("Needs to populate `lag_vars` because `lagging==TRUE`")
  }
  if (cumsum == TRUE && length(cumsum_vars) == 0) {
    stop("Needs to populate `cumsum_vars` because `cumsum==TRUE`")
  }
  if (length(horizon) != 1 || horizon < 1) {
    stop("`horizon` must a single positive number")
  }

  info_msg(paste0("Generating lags for ", horizon, "-week-ahead"))
  lag_tbl_list <- if (lagging == TRUE) {
    tbl_list %>%
      map(
        \(tbl) {
          calculate_lags(
            df = tbl,
            vars = lag_vars,
            lags = seq(horizon, 12 + horizon - 1),
            id_cols = join_idcol
          )
        },
        .progress = TRUE
      )
  } else {
    tbl_list
  }

  info_msg(paste0("Generating cumumlative sums for ", horizon, "-week-ahead"))
  cumsum_tbl_list <- if (cumsum == TRUE) {
    tbl_list %>%
      map(
        \(tbl) {
          calculate_cum_sums(
            df = tbl,
            vars = cumsum_vars,
            start = horizon,
            lengths = 2:12,
            id_cols = join_idcol
          )
        },
        .progress = TRUE
      )
  } else {
    tbl_list
  }

  select_vars <- unique(c(
    select_vars,
    colnames(lag_tbl_list[[1]]),
    colnames(cumsum_tbl_list[[1]])
  ))

  joined_tbl_list <- pmap(
    list(tbl_list, lag_tbl_list, cumsum_tbl_list),
    \(tbl, lag_tbl, cumsum_tbl) {
      tbl %>%
        left_join(lag_tbl, by = join_idcol) %>%
        left_join(cumsum_tbl, by = join_idcol) %>%
        select(all_of(c(join_idcol, select_vars))) %>%
        # drop the first (max lag amount) + (max cumsum window) rows
        tail(-(12 + 12))
    }
  )

  gids <- names(joined_tbl_list)

  info_msg(paste0("Generating tasks for ", horizon, "-week-ahead"))
  tsk_list <- map(
    gids,
    \(gid) {
      joined_tbl_list[[gid]] %>%
        mutate(
          district = gid,
          date_num = as.numeric(date)
        ) %>%
        as_task_fcst(
          target = "n",
          order = "date",
          freq = "1 week",
          id = sprintf("gid-%s_fh-%d_wa", gid, horizon)
        )
    },
    .progress = TRUE
  ) %>%
    setNames(gids)

  tsk_list
}

build_task_list <- function(
  gid_data_list,
  max_horizon,
  lag_cumsum_vars = c("n")
) {
  forecast_horizons <- seq(1, as.integer(max_horizon), by = 1)

  tsk_feateng_list <- map(
    forecast_horizons,
    \(fh) {
      fcst_task_builder(
        gid_data_list,
        horizon = fh,
        select_vars = c("n"),
        lag_vars = lag_cumsum_vars,
        cumsum_vars = lag_cumsum_vars
      )
    }
  ) %>%
    setNames(
      paste0("fh", forecast_horizons, "wa")
    )

  list_flatten(tsk_feateng_list, name_spec = "{outer}_{inner}")
}
