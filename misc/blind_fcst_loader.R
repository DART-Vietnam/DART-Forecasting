library(tidyverse)
library(targets)
library(ggplot2)

source("misc/zzz_helper.R")

theme_set(theme_bw())
tar_load(weekly_data)
tar_load(blind_fcst_tbl)


hist_ts <- weekly_data %>%
  filter(date > "2026-01-01") %>%
  select(-region) %>%
  rename(response = n) %>%
  mutate(interval = list(c(0.5, 0.75, 0.9, 0.95, 0.99))) %>%
  unnest(interval) %>%
  mutate(lower = response, upper = response, type = "hist")

fcst_ts <- blind_fcst_tbl %>%
  bind_rows(
    hist_ts %>% filter(date == max(date))
  ) %>%
  mutate(type = "fcst")


bind_rows(fcst_ts, hist_ts) %>%
  mutate(interval = as.factor(interval)) %>%
  ggplot(aes(x = date)) +
  geom_ribbon(
    aes(
      ymax = upper,
      ymin = lower,
      group = interval,
      fill = interval
    ),
    alpha = 0.1,
    fill = "blue"
  ) +
  geom_line(aes(y = response, color = type)) +
  scale_color_manual(
    name = "Line type",
    values = c("red", "black"),
    labels = c("Forecast", "Historical")
  ) +
  scale_fill_manual(
    name = "Interval",
    values = ribbon_pal,
    labels = names(ribbon_pal) %>%
      as.numeric %>%
      `*`(100) %>%
      as.character() %>%
      paste("%"),
    na.translate = FALSE,
    na.value = "transparent"
  ) +
  scale_x_date(
    "Date",
    date_labels = "W%V/%Y"
  ) +
  scale_y_continuous("Weekly incidence")


blind_fcst_tbl %>%
  relocate(date, .before = everything()) %>%
  write_csv("VNM-1-regr.ranger-wrf_ds-2026_03_16.csv")
