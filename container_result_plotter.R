library(tidyverse)
library(targets)
library(ggplot2)

Sys.setenv(TOML_CONF_FPATH = "targets_config.toml")

tar_config_set(
  store = "container_targets"
)
tar_path_store()

tar_load("blind_fcst_tbl")
tar_load("weekly_data")

hist_ts <- weekly_data %>%
  filter(date > "2025-01-01")
last_hist_ts_row <- hist_ts %>% tail(1)

blind_fcst_tbl %>%
  bind_rows(hist_ts) %>%
  ggplot(aes(x = date)) +
  geom_ribbon(
    aes(ymin = lower, ymax = upper, group = interval),
    fill = "blue",
    alpha = 0.2
  ) +
  geom_line(aes(y = n), color = "black") +
  geom_line(aes(y = response), color = "red")
