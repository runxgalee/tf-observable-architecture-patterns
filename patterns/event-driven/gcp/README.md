# GCP Event-Driven Architecture - Terraform

Pub/SubとCloud Runを使用したイベント駆動アーキテクチャのTerraform実装（ベストプラクティス準拠）

## ディレクトリ構造

```
gcp/
├── modules/
│   └── event-driven/           # 再利用可能なモジュール
│       ├── versions.tf         # Terraform/プロバイダーバージョン
│       ├── main.tf             # データソース、ローカル変数
│       ├── pubsub.tf           # Pub/Sub Topic, Subscription
│       ├── cloudrun.tf         # Cloud Run Service
│       ├── iam.tf              # Service Account, IAM bindings
│       ├── monitoring.tf       # Cloud Monitoring alerts
│       ├── observability.tf    # Cloud Trace, Error Reporting, Dashboard
│       ├── variables.tf        # 変数定義
│       └── outputs.tf          # 出力定義
└── environments/
    ├── dev/                    # 開発環境
    │   ├── providers.tf        # プロバイダー設定
    │   ├── backend.tf          # State管理設定
    │   ├── main.tf             # モジュール呼び出し
    │   ├── variables.tf        # 変数定義
    │   ├── outputs.tf          # 出力定義
    │   └── terraform.tfvars.example
    └── prod/                   # 本番環境
        ├── providers.tf
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

## アーキテクチャ概要

```
Publisher → Pub/Sub Topic → Push Subscription → Cloud Run (Event Processor)
                ↓ (失敗時)
         Dead Letter Topic → Alert
```

### 構成リソース

| リソース | 用途 | ファイル |
|---------|------|---------|
| **Pub/Sub Topic** | イベントメッセージの配信 | `pubsub.tf` |
| **Pub/Sub Subscription** | Push型でCloud Runにメッセージ配信 | `pubsub.tf` |
| **Cloud Run Service** | イベント処理ロジックの実行 | `cloudrun.tf` |
| **Service Accounts** | 最小権限での実行 | `iam.tf` |
| **Dead Letter Queue** | 処理失敗メッセージの保存 | `pubsub.tf` |
| **Monitoring Alerts** | 監視アラート | `monitoring.tf` |
| **Cloud Trace** | 分散トレーシング | `observability.tf` |
| **Error Reporting** | エラー追跡と集約 | `observability.tf` |
| **Monitoring Dashboard** | メトリクスの可視化 | `observability.tf` |

## ベストプラクティス

この実装は以下のTerraformベストプラクティスに準拠しています：

### 1. 環境分離
- **dev/prod完全分離**: 各環境で独立したState管理
- **環境固有設定**: 環境ごとに最適化された設定値

### 2. リソース分割
- **責務ごとにファイル分割**: pubsub.tf, cloudrun.tf, iam.tf, monitoring.tf
- **可読性向上**: ファイルサイズを小さく保つ
- **保守性向上**: 変更時の影響範囲が明確

### 3. モジュール化
- **再利用可能**: 他のプロジェクトでも利用可能
- **DRY原則**: 重複コードの排除
- **バージョン管理**: モジュールのバージョン管理が容易

### 4. セキュリティ
- **最小権限の原則**: 各Service Accountに必要最小限の権限
- **OIDC認証**: Pub/Sub → Cloud Run間の認証
- **State暗号化**: GCSバックエンドでのState保護

### 5. 監視・運用
- **包括的なアラート**: DLQ、エラー率、処理遅延の監視
- **構造化ログ**: JSON形式のログ出力
- **カスタムメトリクス**: アプリケーション固有のメトリクス

## 前提条件

1. GCP プロジェクトの作成
2. 必要なAPIの有効化:
```bash
gcloud services enable pubsub.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudtrace.googleapis.com
gcloud services enable clouderrorreporting.googleapis.com
gcloud services enable logging.googleapis.com
```

3. Terraform のインストール (>= 1.0)

4. GCP認証の設定:
```bash
gcloud auth application-default login
```

## デプロイ手順

### 開発環境（dev）のデプロイ

#### 1. 環境ディレクトリに移動
```bash
cd environments/dev
```

#### 2. 設定ファイルの準備
```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集:
```hcl
project_id = "your-dev-project-id"
container_image = "gcr.io/your-project/event-processor:dev"
```

#### 3. Terraform の初期化
```bash
terraform init
```

#### 4. 実行計画の確認
```bash
terraform plan
```

#### 5. リソースの作成
```bash
terraform apply
```

#### 6. 出力の確認
```bash
terraform output
```

### 本番環境（prod）のデプロイ

#### 1. GCS バケットの作成（State管理用）
```bash
# State管理用のGCSバケットを作成
gcloud storage buckets create gs://your-terraform-state-bucket \
  --project=your-prod-project-id \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

# バージョニングを有効化
gcloud storage buckets update gs://your-terraform-state-bucket --versioning
```

#### 2. backend.tf の編集
```bash
cd environments/prod
```

`backend.tf` を編集してバケット名を設定:
```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "terraform/event-driven/prod"
  }
}
```

#### 3. 設定ファイルの準備
```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集（本番環境用の値を設定）:
```hcl
project_id = "your-prod-project-id"
container_image = "gcr.io/your-project/event-processor:v1.0.0"
min_instances = 1  # 本番は常時起動
notification_channels = [
  "projects/your-project/notificationChannels/1234567890"
]
```

#### 4. 通知チャネルの作成
```bash
gcloud alpha monitoring channels create \
  --display-name="Production Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@example.com \
  --project=your-prod-project-id
```

#### 5. デプロイ
```bash
terraform init
terraform plan
terraform apply
```

## コンテナイメージの準備

### サンプルアプリケーション (Python/Flask)

`app/app.py`:
```python
from flask import Flask, request, jsonify
import os
import json
import base64
import logging

# ログ設定
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='{"timestamp":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    """ヘルスチェックエンドポイント"""
    return jsonify({"status": "healthy"}), 200

@app.route('/', methods=['POST'])
def index():
    """Pub/Subメッセージハンドラ"""
    envelope = request.get_json()
    if not envelope:
        logger.error("No Pub/Sub message received")
        return 'Bad Request: no Pub/Sub message received', 400

    if not isinstance(envelope, dict) or 'message' not in envelope:
        logger.error("Invalid Pub/Sub message format")
        return 'Bad Request: invalid Pub/Sub message format', 400

    pubsub_message = envelope['message']

    # メッセージIDとタイムスタンプを取得
    message_id = pubsub_message.get('messageId', 'unknown')
    publish_time = pubsub_message.get('publishTime', 'unknown')

    # メッセージデータをデコード
    if 'data' in pubsub_message:
        data = base64.b64decode(pubsub_message['data']).decode('utf-8')
        logger.info(f"Received message: {message_id} at {publish_time}")

        try:
            # イベント処理
            process_event(data, message_id)
            logger.info(f"Event processed successfully: {message_id}")
            return ('', 204)
        except Exception as e:
            logger.error(f"Error processing event {message_id}: {str(e)}")
            # 500エラーを返すとPub/Subが再試行する
            return f'Error processing event: {str(e)}', 500

    return ('', 204)

def process_event(data, message_id):
    """イベント処理ロジック"""
    try:
        event_data = json.loads(data)
        event_type = event_data.get('event_type', 'unknown')

        logger.info(f"Processing event type: {event_type}, message_id: {message_id}")

        # ここにビジネスロジックを実装
        # 例: データベース書き込み、外部API呼び出しなど

        # 処理成功のログ
        logger.info(f"Event processing completed: {message_id}")

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON data: {e}")
        raise
    except Exception as e:
        logger.error(f"Error in process_event: {e}")
        raise

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

`app/Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# 非rootユーザーで実行
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app
```

`app/requirements.txt`:
```
Flask==3.0.0
gunicorn==21.2.0
```

### ビルドとデプロイ

```bash
# 開発環境用
cd app
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/event-processor:dev

# 本番環境用（バージョンタグ付き）
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/event-processor:v1.0.0

# terraform.tfvars を更新
container_image = "gcr.io/YOUR_PROJECT_ID/event-processor:dev"

# 再デプロイ
cd ../environments/dev
terraform apply
```

## 使用方法

### メッセージの送信

```bash
# 開発環境
gcloud pubsub topics publish dev-events-events \
  --message='{"event_type": "user.created", "user_id": "12345"}' \
  --project=your-dev-project-id

# 本番環境
gcloud pubsub topics publish prod-events-events \
  --message='{"event_type": "user.created", "user_id": "12345"}' \
  --project=your-prod-project-id
```

### ログの確認

```bash
# terraformのoutputからコマンドを取得
terraform output view_logs_command

# または直接実行
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=dev-events-event-processor" \
  --limit 50 --format json --project=your-dev-project-id
```

### 監視

```bash
# 未配信メッセージ数の確認
gcloud pubsub subscriptions describe dev-events-events-subscription \
  --format="value(numUndeliveredMessages)" \
  --project=your-dev-project-id

# Dead Letter Queue の確認
gcloud pubsub subscriptions pull dev-events-events-dead-letter-subscription \
  --limit=10 --project=your-dev-project-id

# Cloud Runのメトリクス確認
gcloud monitoring time-series list \
  --filter='metric.type="run.googleapis.com/request_count"' \
  --project=your-dev-project-id
```

## 環境ごとの設定の違い

| 設定項目 | Dev | Prod |
|---------|-----|------|
| **min_instances** | 0 (コスト削減) | 1 (常時起動) |
| **max_instances** | 10 | 100 |
| **cpu_limit** | 1 | 2 |
| **memory_limit** | 512Mi | 1Gi |
| **log_level** | DEBUG | INFO |
| **cpu_always_allocated** | false | true |
| **error_rate_threshold** | 10/s | 5/s |
| **state backend** | local | GCS |
| **exactly_once_delivery** | false | true |

## トラブルシューティング

### メッセージが処理されない

1. Cloud Run のログを確認:
```bash
terraform output view_logs_command
```

2. Subscription の設定を確認:
```bash
gcloud pubsub subscriptions describe SUBSCRIPTION_NAME
```

3. サービスのヘルスチェック:
```bash
curl $(terraform output -raw cloud_run_url)/health
```

### 権限エラー

Service Account の権限を確認:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:dev-events-event-processor@*"
```

### Dead Letter Queue にメッセージが蓄積

1. エラーログを確認
2. 失敗したメッセージを取得:
```bash
gcloud pubsub subscriptions pull DLQ_SUBSCRIPTION_NAME --limit=5
```
3. 原因を修正後、必要に応じて再処理

## クリーンアップ

```bash
# 開発環境の削除
cd environments/dev
terraform destroy

# 本番環境の削除（注意！）
cd environments/prod
terraform destroy
```

## Observability（可観測性）

このテンプレートには包括的なObservability機能が組み込まれています。

### 1. Cloud Monitoring Dashboard

デプロイ後、以下のメトリクスを可視化するダッシュボードが自動作成されます：

**Pub/Subメトリクス**
- メッセージ送信レート
- 未配信メッセージ数
- Dead Letter Queueメッセージ数

**Cloud Runメトリクス**
- リクエストレート
- エラー率（2xx/4xx/5xx別）
- レイテンシ（p50/p95/p99パーセンタイル）
- インスタンス数
- CPU/メモリ使用率

**ログメトリクス**
- エラーログ数

ダッシュボードURL:
```bash
terraform output monitoring_dashboard_url
```

### 2. Cloud Trace（分散トレーシング）

Cloud Traceはデフォルトで有効になっており、リクエストのエンドツーエンドの追跡が可能です。

**アプリケーションでの実装例（Python）**

```python
from google.cloud import trace_v2
from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import os

# Cloud Traceが有効かチェック
if os.getenv('GOOGLE_CLOUD_TRACE_ENABLED', 'false') == 'true':
    # OpenTelemetryの設定
    tracer_provider = TracerProvider()
    cloud_trace_exporter = CloudTraceSpanExporter()
    tracer_provider.add_span_processor(
        BatchSpanProcessor(cloud_trace_exporter)
    )
    trace.set_tracer_provider(tracer_provider)
    tracer = trace.get_tracer(__name__)
else:
    tracer = None

def process_event(data, message_id):
    """イベント処理ロジック（トレーシング対応）"""
    if tracer:
        with tracer.start_as_current_span("process_event") as span:
            span.set_attribute("message_id", message_id)
            span.set_attribute("event_type", data.get('event_type', 'unknown'))

            # ビジネスロジック
            with tracer.start_as_current_span("business_logic"):
                # 処理内容
                pass
    else:
        # トレーシングなしの処理
        pass
```

**必要なパッケージ（requirements.txt）**
```
google-cloud-trace>=1.11.0
opentelemetry-api>=1.20.0
opentelemetry-sdk>=1.20.0
opentelemetry-exporter-gcp-trace>=1.6.0
```

トレースの確認:
```bash
terraform output cloud_trace_url
```

### 3. Cloud Error Reporting

エラーは自動的にCloud Error Reportingに集約されます。

**構造化エラーログの例（Python）**

```python
import logging
import json
from google.cloud.error_reporting import Client as ErrorReportingClient

# Error Reportingクライアント（オプション）
error_client = None
if os.getenv('GOOGLE_CLOUD_ERROR_REPORTING_ENABLED', 'false') == 'true':
    error_client = ErrorReportingClient()

def handle_error(error, context):
    """エラーハンドリング"""
    # 構造化ログでエラーを記録（自動的にError Reportingに送信）
    error_log = {
        "severity": "ERROR",
        "@type": "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent",
        "message": str(error),
        "context": {
            "reportLocation": {
                "filePath": __file__,
                "lineNumber": 0,
                "functionName": context.get('function', 'unknown')
            }
        }
    }
    logger.error(json.dumps(error_log))

    # または Error Reporting クライアント経由
    if error_client:
        error_client.report_exception()
```

Error Reportingの確認:
```bash
terraform output error_reporting_url
```

### 4. アラートポリシー

以下のアラートが自動設定されます：

| アラート | 条件 | 用途 |
|---------|------|------|
| **Dead Letter Queue** | メッセージ数 > 閾値 | 処理失敗の検知 |
| **High Error Rate** | エラーレート > 5/s | アプリケーションエラーの検知 |
| **Old Unacked Messages** | 最古メッセージ > 300s | 処理遅延の検知 |
| **Error Reporting** | エラー発生率 > 1/s | エラー急増の検知 |

通知チャネルの設定:
```hcl
# terraform.tfvars
notification_channels = [
  "projects/your-project/notificationChannels/1234567890"
]
```

### 5. ログの確認

**Cloud Loggingコンソール**
```bash
terraform output cloud_logging_url
```

**gcloudコマンド**
```bash
# エラーログのみ
gcloud logging read \
  'resource.type="cloud_run_revision"
   resource.labels.service_name="SERVICE_NAME"
   severity>=ERROR' \
  --limit 50 \
  --format json

# 特定のメッセージIDでフィルタ
gcloud logging read \
  'resource.type="cloud_run_revision"
   jsonPayload.message_id="MESSAGE_ID"' \
  --limit 10
```

### 6. Observability設定のカスタマイズ

**terraform.tfvars での設定例**

```hcl
# Observability機能の有効化/無効化
enable_observability_dashboard = true
enable_cloud_trace            = true
enable_error_reporting_metric = true

# トレースサンプリングレート（0.0～1.0）
# 本番環境では 0.1（10%）、開発環境では 1.0（100%）推奨
trace_sampling_rate = 0.1

# エラーレポートアラート閾値
error_reporting_threshold = 1  # エラー/秒

# オプション: BigQueryへのエラーログシンク
enable_error_log_sink = true
error_log_dataset_id  = "error_logs"  # 事前にBigQueryデータセットを作成
```

### 7. BigQueryでの長期ログ分析（オプション）

エラーログをBigQueryにエクスポートして長期分析が可能です。

**BigQueryデータセットの作成**
```bash
bq mk --dataset \
  --location=asia-northeast1 \
  --description "Error logs for event-driven architecture" \
  YOUR_PROJECT_ID:error_logs
```

**terraform.tfvars**
```hcl
enable_error_log_sink = true
error_log_dataset_id  = "error_logs"
```

**BigQueryでのクエリ例**
```sql
-- 過去24時間のエラー集計
SELECT
  severity,
  COUNT(*) as error_count,
  ARRAY_AGG(DISTINCT jsonPayload.error_type IGNORE NULLS) as error_types
FROM `YOUR_PROJECT_ID.error_logs.cloudrun_googleapis_com_stdout_*`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  AND severity >= 'ERROR'
GROUP BY severity
ORDER BY error_count DESC;

-- エラーメッセージのトレンド分析
SELECT
  TIMESTAMP_TRUNC(timestamp, HOUR) as hour,
  COUNT(*) as error_count
FROM `YOUR_PROJECT_ID.error_logs.cloudrun_googleapis_com_stdout_*`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND severity = 'ERROR'
GROUP BY hour
ORDER BY hour DESC;
```

### 8. Observabilityのベストプラクティス

1. **構造化ログを使用する**: JSON形式でログを出力し、検索とフィルタリングを容易に
2. **適切なサンプリングレート**: 本番環境では10-20%、開発環境では100%
3. **エラーコンテキストを含める**: エラー発生時のメッセージID、ユーザーID、リクエスト詳細を記録
4. **アラート疲れを避ける**: 閾値を適切に設定し、誤検知を減らす
5. **SLO/SLIを定義する**: サービスレベルの目標値を設定し、計測する
6. **定期的なダッシュボードレビュー**: メトリクスを定期的に確認し、異常を早期発見

## 次のステップ

1. **VPC統合**: VPC Connectorを設定してプライベートリソースにアクセス
2. **Secret Manager統合**: 機密情報の安全な管理
3. **CI/CD構築**: GitHub ActionsやCloud Buildでの自動デプロイ
4. **カスタムメトリクス**: ビジネスメトリクスの追加
5. **マルチリージョン**: 複数リージョンでの冗長構成

## 参考資料

- [Pub/Sub から Cloud Run への Push](https://cloud.google.com/run/docs/tutorials/pubsub)
- [Cloud Run のベストプラクティス](https://cloud.google.com/run/docs/tips)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform ベストプラクティス](https://www.terraform-best-practices.com/)
