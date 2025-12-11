# データ仕様メモ

## 5分ごとの環境データ
列案:
- timestamp_5min: 例) 2025-12-11 12:45
- pressure_hPa: iPad Pro 内蔵気圧計の5分平均
- temp_C: 外部センサーからの室温5分平均
- humid_pct: 外部センサーからの湿度5分平均

## VASイベント
- vas_timestamp: 対象者がVASを記録した時刻
- vas_score: 0–100 (今回は50–100域を主に使用)
