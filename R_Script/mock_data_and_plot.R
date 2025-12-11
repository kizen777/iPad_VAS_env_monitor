# scripts/mock_data_and_plot.R
# 2025-12-11

library(dplyr)
library(ggplot2)
library(lubridate)

# ダミーデータ生成（1日分、5分間隔）
set.seed(123)

times <- seq(
  from = ymd_hm("2025-01-01 00:00"),
  to   = ymd_hm("2025-01-01 23:55"),
  by   = "5 min"
)

n <- length(times)

df_env <- tibble(
  timestamp_5min = times,
  pressure_hPa   = 1015 + cumsum(rnorm(n, 0, 0.3)),
  temp_C         = 20 + sin(seq(0, 2*pi, length.out = n)) * 3 + rnorm(n, 0, 0.3),
  humid_pct      = 50 + rnorm(n, 0, 3)
)

# 簡単な気圧の時系列プロット
ggplot(df_env, aes(x = timestamp_5min, y = pressure_hPa)) +
  geom_line() +
  theme_bw()
