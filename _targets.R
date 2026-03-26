# Edit the pipeline setup in `targets_setup.R`
source("targets_setup.R")

# Here, it's just the pipeline
list(
  #
  # Load run-time config
  tar_target(run_conf_fpath, .toml_fpath, format = "file"),
  tar_target(run_conf, toml::read_toml(run_conf_fpath)),
  #
  # Load input data
  tar_target(
    raw_incidence_data,
    read_csv(run_conf$data$paths$incidence)
  ),
  tar_target(
    incidence_data,
    prep_incidence_data(raw_incidence_data, run_conf$forecast$admin_level),
    packages = c(tar_option_get("packages"), "ISOweek")
  ),
  tar_target(
    weather_data,
    {
      if (run_conf$forecast$met_dat_included) {
        load_weather_data(run_conf$data$paths$weather, run_conf$forecast)
      } else {
        NULL
      }
    },
    packages = c(tar_option_get("packages"), "stars", "ISOweek")
  ),
  tar_target(
    weekly_data,
    build_weekly_data(incidence_data, weather_data)
  ),
  #
  # Build feature-engineered flatlist
  tar_target(
    tsk_feateng_flatlist,
    build_task_list(
      weekly_data = weekly_data,
      max_horizon = run_conf$forecast$max_horizon,
      join_idcol = c("date", "region")
    ),
    packages = c(tar_option_get("packages"), "mlr3", "mlr3forecast")
  ),
  #
  # Load tuned learners
  tar_target(
    tuned_lrners_flatlist,
    load_tuned_lrners_flatlist(
      run_conf$data$paths$mlr3_objs,
      run_conf$forecast
    ),
    packages = c(tar_option_get("packages"), "qs2")
  ),
  #
  # Get train-calib period split indices
  tar_target(
    train_calib_split_indices,
    get_split_indices(tsk_feateng_flatlist[[1]], percentage = 0.75)
  ),
  tar_target(
    flatlist_ids,
    names(tuned_lrners_flatlist), # can be any flatlist object really
  ),
  # Perform Conformal Prediction -----------------------------------------------
  #
  ## Run tuned models on full train period -------------------------------------
  tar_target(
    full_train_preds,
    full_train_resampling(
      tsk_feateng_flatlist,
      tuned_lrners_flatlist,
      train_calib_split_indices,
      flatlist_ids
    ),
    pattern = map(tsk_feateng_flatlist, tuned_lrners_flatlist, flatlist_ids),
    iteration = "list",
    packages = c(tar_option_get("packages"), "mlr3")
  ),
  tar_target(
    full_train_preds_flatlist,
    recomb_into_flatlist(full_train_preds, "full_train_preds")
  ),
  #
  ## Calculate ACI conformity score set from proper train predictions ----------
  tar_target(p_ints, c(0.5, 0.75, 0.9, 0.95, 0.99)),
  tar_target(
    agaci_obj_list,
    build_agaci_obj(
      full_train_preds_flatlist,
      train_calib_split_indices,
      p_ints
    ),
    pattern = map(full_train_preds_flatlist),
    iteration = "list",
    packages = c(tar_option_get("packages"), "AdaptiveConformal")
  ),
  #
  ## Online updating/Calibrating AgACI from calibration predictions ------------
  tar_target(
    calibrated_agaci_obj_list,
    calibrate_agaci_obj(
      agaci_obj_list,
      full_train_preds_flatlist,
      train_calib_split_indices
    ),
    pattern = map(agaci_obj_list, full_train_preds_flatlist),
    iteration = "list",
    packages = c(tar_option_get("packages"), "opera")
  ),
  # Blind forecasting ----------------------------------------------------------
  #
  ## Train the tuned learners --------------------------------------------------
  tar_target(
    trained_tuned_lrners,
    train_lrners(tuned_lrners_flatlist, tsk_feateng_flatlist),
    pattern = map(tuned_lrners_flatlist, tsk_feateng_flatlist),
    iteration = "list",
    packages = c(
      tar_option_get("packages"),
      "mlr3",
      "mlr3pipelines",
      "mlr3learners",
      "ranger"
    )
  ),
  tar_target(
    trained_tuned_lrners_flatlist,
    recomb_into_flatlist(trained_tuned_lrners, "trained_lrner")
  ),
  #
  # Get train-calib period split indices
  tar_target(
    train_calib_split_indices,
    get_split_indices(tsk_feateng_flatlist[[1]], percentage = 0.8)
  ),
  #
  # Train-calib period splitting
  tar_target(
    splitted_tsk_flatlist,
    split_task_list(tsk_feateng_flatlist, train_calib_split_indices)
  ),
  tar_target(
    train_tsk_flatlist,
    splitted_tsk_flatlist$train_tsk_list,
    iteration = "list"
  ),
  tar_target(
    calib_tsk_flatlist,
    splitted_tsk_flatlist$test_tsk_list,
    iteration = "list"
  ),
  tar_target(
    flatlist_ids,
    names(train_tsk_flatlist), # can be any flatlist object really
  ),
  ################ Perform Conformal Prediction
  #
  # Run tuned models on full train period
  tar_target(
    full_train_preds,
    full_train_resampling(
      train_tsk_flatlist,
      tuned_lrners_flatlist,
      train_calib_split_indices,
      flatlist_ids
    ),
    pattern = map(train_tsk_flatlist, tuned_lrners_flatlist, flatlist_ids),
    iteration = "list",
    packages = c(tar_option_get("packages"), "mlr3")
  ),
  tar_target(
    full_train_preds_flatlist,
    recomb_into_flatlist(full_train_preds, "full_train_preds")
  ),
  #
  # Create `newdata` flat list
  tar_target(
    newdata_flatlist,
    build_newdata_flatlist(tsk_feateng_flatlist)
  ),
  #
  # Blind forecasting since last available data
  tar_target(
    blind_fcst_flatlist,
    blind_fcst(trained_tuned_lrners_flatlist, newdata_flatlist),
    pattern = map(trained_tuned_lrners_flatlist, newdata_flatlist),
    iteration = "list"
  ),
  #
  # Blind forecasting aggregator
  tar_target(
    blind_fcst_orig_date,
    newdata_flatlist[[1]]$date_num %>% as.Date()
  ),
  tar_target(
    blind_fcst_tbl,
    aggregate_blind_fcsts(blind_fcst_flatlist, blind_fcst_orig_date)
  )
)
