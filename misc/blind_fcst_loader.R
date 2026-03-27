library(tidyverse)
library(targets)
library(ggplot2)

source("zzz_helper.R")

theme_set(theme_bw())
tar_load(blind_fcst_tbl)

blind_fcst_tbl %>%
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
  geom_line(aes(y = response)) +
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
  )


blind_fcst_tbl %>%
  relocate(date, .before = everything()) %>%
  write_csv("VNM-1-regr.ranger-incVars-2026_03_16.csv")
