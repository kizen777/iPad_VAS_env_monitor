# iPad VAS Env Monitor

- 目的: iPad Pro の内蔵気圧計と外部センサーを用いて、5分毎の気圧・室温・湿度を記録し、VASイベントも併記する。
- ローカル環境: MacBook Pro M4 16インチ, RStudio。
- 今後の予定: データ形式の設計、Rによる解析コード作成、iPadアプリ設計。

## プロジェクト構成

├── Output                  # 解析結果の出力一式
│   ├── Figures             # 図ファイル（.png など）
│   └── Reports             # 将来のレポート用出力（.html, .pdf など）
├── README.md               # プロジェクト概要と使い方
├── R_Script                # 解析用 R スクリプト
│   └── 01_mock_data_and_plot.R  # ダミーデータ生成とプロット
├── data
│   ├── processed           # 前処理後データ（解析に使用）
│   └── raw                 # 生データ（上書き・編集しない）
├── docs                    # ドキュメント・メモ
│   └── data_spec.md        # データ仕様・変数の説明
└── ipad_VAS_env_monitor.Rproj  # R プロジェクトファイル