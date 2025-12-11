# scripts/mock_data_and_plot.R
# 2025-12-11

library(dplyr)
library(ggplot2)
library(lubridate)
library(scales)

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
  temp_C         = 20 + sin(seq(0, 2*pi, length.out = n)) * 3 +
    rnorm(n, 0, 0.3),
  humid_pct      = 50 + rnorm(n, 0, 3)
)

# 0時から4時間ごとの投薬時刻を生成
dose_times <- seq(
  from = ymd_hm("2025-01-01 00:00"),
  to   = ymd_hm("2025-01-02 00:00"),
  by   = "4 hours"
)

# ==== VASイベント（4時間おき）を定義 ====
df_vas <- tibble(
  vas_time = ymd_hm(c(
    "2025-01-01 00:25",
    "2025-01-01 04:05",
    "2025-01-01 08:15",
    "2025-01-01 09:45",
    "2025-01-01 12:10",
    "2025-01-01 16:12",
    "2025-01-01 18:09",
    "2025-01-01 18:48",
    "2025-01-01 20:20",
    "2025-01-01 21:47",
    "2025-01-01 22:25",
    "2025-01-01 23:50"
  )),
  vas_score = c(82, 78, 85, 80, 89, 94, 92, 88, 90, 95, 93, 97)
)

# ==== 気圧レンジに少し余裕を持たせてY軸を決める ====
p_min <- min(df_env$pressure_hPa)
p_max <- max(df_env$pressure_hPa)

y_min <- floor(p_min) - 0.2   # 例: 実測最小より少し下
y_max <- ceiling(p_max) + 0.2 # 例: 実測最大より少し上

# VAS 70–100 を左軸 y_min–y_max に線形対応させる係数
#   left = a + b * (VAS - 70)
b <- (y_max - y_min) / 30      # 30 = 100 - 70
a <- y_min

# 簡単な気圧の時系列プロット
p <- 
  ggplot(df_env, aes(x = timestamp_5min,
                   y = pressure_hPa)) +
  geom_line(color = "blue", linewidth = 0.8) +
  # geom_line(color = "#1f4e79") +
  
  # 4時間ごとの投薬時刻に縦線を引く
  geom_vline(
    xintercept = dose_times,
    color      = "#d62728",   # 推奨色：やや落ち着いた赤
    linewidth  = 0.4,
    linetype   = "dashed"
  ) +
  
  # VAS を右軸 70–100 に合わせてスケーリングしてドット表示
  geom_point(
    data = df_vas,
    aes(
      x = vas_time,
      # 左Y軸に写像： a + b * (VAS - 70)
      y = a + b * (vas_score - 70)
    ),
    inherit.aes = FALSE,
    shape  = 21,          # 枠と塗りつぶしを持つ丸
    size   = 6,
    color  = "red",
    fill   = "orange",
    stroke = 1            # 枠線の太さ
  ) +
  
  # 左軸：気圧。右軸：VAS（70–100）の線形変換
  scale_y_continuous(
    name   = "Pressure (hPa)",
    limits = c(y_min, y_max),
    sec.axis = sec_axis(
      # 逆変換： VAS = ((left - a) / b) + 70
      trans = ~ ((. - a) / b) + 70,
      name  = "VAS",
      breaks = seq(70, 100, by = 5)
    )
  ) +
  
  labs(
    x = "Time (5-min sampling)",      # ここで軸ラベルを指定
    y = "Pressure (hPa)"
  ) +
  
  annotate(
    "text",
    x       = times[25],      # 2025-01-01 00:30 を利用
    y       = y_max,          # y座標（上側に配置）
    label   = "2025-Jan-01",
    size    = 10,
    family  = "Times New Roman",
    fontface = "bold",
    vjust   = -0.2            # 少しグラフ内に押し込む場合は調整
  ) +
  
  scale_x_datetime(
    date_labels = "%H:%M",  # X軸のラベルを "HH:MM" 形式にする
    date_breaks = "1 hours" # 1時間ごとに目盛を表示する
  ) +
  
  theme_bw() +
  
  theme(
    # X軸タイトル（横軸ラベル：例 "Time"）の書式設定
    axis.title.x = element_text(
      family = "Times New Roman",  # フォントを Times New Roman にする
      face   = "bold",             # 太字にする
      size   = 13                  # 文字サイズを 13 にする
    ),
    
    # Y軸タイトル（縦軸ラベル：例 "Pressure (hPa)"）の書式設定
    axis.title.y = element_text(
      family = "Times New Roman",  # フォントを Times New Roman にする
      face   = "bold",             # 太字にする
      size   = 13                  # 文字サイズを 13 にする
    ),
    
    # X軸の目盛ラベル（軸の下に並ぶ 0, 1, Jan など）の書式設定
    axis.text.x = element_text(
      family = "Times New Roman",  # フォントを Times New Roman にする
      face   = "bold",             # 太字にする
      size   = 10                  # 文字サイズを 10 にする
    ),
    
    # Y軸の目盛ラベル（軸の横に並ぶ 1000, 1010, … など）の書式設定
    axis.text.y = element_text(
      family = "Times New Roman",  # フォントを Times New Roman にする
      face   = "bold",             # 太字にする
      size   = 10                  # 文字サイズを 10 にする
    )
  )

print(p)

# データを回帰用に整形 ==============================
p_reg <- ggplot(df_reg, aes(x = pressure_hPa, y = vas_score)) +
  # 点：時系列と同じスタイル
  geom_point(
    shape  = 21,
    size   = 6,
    color  = "red",
    fill   = "orange",
    stroke = 1
  ) +
  # 回帰直線：時系列の line と同じ色・太さ
  geom_smooth(
    method = "lm",
    se     = TRUE,
    color  = "blue",
    linewidth = 0.8
  ) +
  # 回帰式の注釈
  annotate(
    "text",
    x       = min(df_reg$pressure_hPa),
    y       = max(df_reg$vas_score),
    hjust   = 0,
    vjust   = 1,
    label   = label_lm,
    family  = "Times New Roman",
    fontface = "bold",
    size    = 5
  ) +
  labs(x = "Pressure (hPa)", y = "VAS") +
  theme_bw() +
  theme(
    axis.title.x = element_text(
      family = "Times New Roman",
      face   = "bold",
      size   = 13
    ),
    axis.title.y = element_text(
      family = "Times New Roman",
      face   = "bold",
      size   = 13
    ),
    axis.text.x = element_text(
      family = "Times New Roman",
      face   = "bold",
      size   = 10
    ),
    axis.text.y = element_text(
      family = "Times New Roman",
      face   = "bold",
      size   = 10
    )
  )

print(p_reg)
