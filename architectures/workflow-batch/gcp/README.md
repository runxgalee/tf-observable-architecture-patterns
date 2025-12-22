# GCP Workflow Batch Pattern - Terraform

Cloud Scheduler、Workflows、Cloud Run Jobを使用したワークフロー型バッチ処理パターンのTerraform実装（ベストプラクティス準拠）

## ディレクトリ構造

```
gcp/
├── modules/
│   └── workflow-batch/          # 再利用可能なモジュール
│       ├── versions.tf          # Terraform/プロバイダーバージョン
│       ├── main.tf              # データソース、ローカル変数
│       ├── scheduler.tf         # Cloud Scheduler Job
│       ├── workflows.tf         # Workflows定義
│       ├── workflow.yaml        # Workflowロジック定義
│       ├── cloudrun-job.tf      # Cloud Run Job
│       ├── iam.tf               # Service Account, IAM bindings
│       ├── monitoring.tf        # Cloud Monitoring alerts
│       ├── variables.tf         # 変数定義
│       └── outputs.tf           # 出力定義
└── environments/
    ├── dev/                     # 開発環境
    │   ├── providers.tf         # プロバイダー設定
    │   ├── backend.tf           # State管理設定
    │   ├── main.tf              # モジュール呼び出し
    │   ├── variables.tf         # 変数定義
    │   ├── outputs.tf           # 出力定義
    │   └── terraform.tfvars.example
    └── prod/                    # 本番環境
        ├── providers.tf
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

## アーキテクチャ概要

```
Cloud Scheduler (定期実行)
    ↓
Workflows (オーケストレーション)
    ↓
Cloud Run Job (バッチ処理)
    ↓
処理結果 (ログ/Storage/DB等)
```

### ワークフローフロー

1. **Cloud Scheduler**: 設定されたスケジュール（cron式）でWorkflowsを起動
2. **Workflows**:
   - Cloud Run Jobを実行
   - ジョブの完了を監視
   - エラーハンドリング・リトライ処理
   - 実行結果のログ記録
3. **Cloud Run Job**: コンテナ化されたバッチ処理を実行

### 構成リソース

| リソース | 用途 | ファイル |
|---------|------|---------|
| **Cloud Scheduler Job** | 定期的なワークフロートリガー | `scheduler.tf` |
| **Workflows** | ジョブオーケストレーション | `workflows.tf` |
| **Cloud Run Job** | コンテナ化バッチ処理 | `cloudrun-job.tf` |
| **Service Accounts** | 最小権限での実行 | `iam.tf` |
| **Monitoring Alerts** | 監視アラート | `monitoring.tf` |
| **Dashboard** | メトリクスの可視化 | `monitoring.tf` |

## ベストプラクティス

この実装は以下のTerraformベストプラクティスに準拠しています：

### 1. 環境分離
- **dev/prod完全分離**: 各環境で独立したState管理
- **環境固有設定**: 環境ごとに最適化された設定値（リソース、タイムアウト等）

### 2. リソース分割
- **責務ごとにファイル分割**: scheduler.tf, workflows.tf, cloudrun-job.tf, iam.tf, monitoring.tf
- **可読性向上**: ファイルサイズを小さく保つ
- **保守性向上**: 変更時の影響範囲が明確

### 3. モジュール化
- **再利用可能**: 他のプロジェクトでも利用可能
- **DRY原則**: 重複コードの排除
- **バージョン管理**: モジュールのバージョン管理が容易

### 4. セキュリティ
- **最小権限の原則**: 各Service Accountに必要最小限の権限
- **OIDC認証**: Scheduler → Workflows、Workflows → Cloud Run Job間の認証
- **State暗号化**: GCSバックエンドでのState保護（prod）

### 5. 監視・運用
- **包括的なアラート**: Workflow失敗、Job失敗、Scheduler失敗の監視
- **構造化ログ**: JSON形式のログ出力
- **ダッシュボード**: 実行状況の可視化

### 6. エラーハンドリング
- **自動リトライ**: Workflowsレベルでの自動リトライ（Exponential Backoff）
- **Job-levelリトライ**: Cloud Run Jobでのタスクリトライ
- **詳細なログ**: エラー原因の追跡が容易

## 前提条件

1. GCP プロジェクトの作成
2. 必要なAPIの有効化:
```bash
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable workflows.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
```

3. 認証設定:
```bash
gcloud auth application-default login
```

4. バッチジョブ用のコンテナイメージの準備:
```bash
# Example: Build and push your batch job image
docker build -t gcr.io/YOUR_PROJECT_ID/batch-job:latest .
docker push gcr.io/YOUR_PROJECT_ID/batch-job:latest
```

## デプロイ手順

### 開発環境 (dev)

```bash
# 1. ディレクトリ移動
cd architectures/workflow-batch/gcp/environments/dev

# 2. 設定ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# 3. terraform.tfvars を編集
# - project_id を設定
# - job_image を設定
# - (オプション) その他のパラメータを調整

# 4. Terraform初期化
terraform init

# 5. プラン確認
terraform plan

# 6. デプロイ実行
terraform apply

# 7. 出力の確認
terraform output
```

### 本番環境 (prod)

```bash
# 1. State管理用GCSバケットの作成
gcloud storage buckets create gs://your-terraform-state-bucket \
  --project=your-prod-project-id \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

# 2. ディレクトリ移動
cd architectures/workflow-batch/gcp/environments/prod

# 3. backend.tf を編集してバケット名を設定

# 4. 設定ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# 5. terraform.tfvars を編集
# - project_id を設定
# - job_image を設定
# - alert_email を設定（必須）
# - (オプション) その他のパラメータを調整

# 6. Terraform初期化
terraform init

# 7. プラン確認
terraform plan

# 8. デプロイ実行
terraform apply

# 9. 出力の確認
terraform output
```

## 設定例

### スケジュール設定

```hcl
# 毎日午前9時（JST）に実行
scheduler_schedule  = "0 9 * * *"
scheduler_time_zone = "Asia/Tokyo"

# 1時間ごとに実行
scheduler_schedule  = "0 * * * *"

# 毎週月曜日の午前10時に実行
scheduler_schedule  = "0 10 * * 1"
```

### ジョブリソース設定

```hcl
# 開発環境: 小規模ジョブ
job_cpu    = "1000m"   # 1 vCPU
job_memory = "512Mi"   # 512MB
job_timeout = "600s"   # 10分

# 本番環境: 大規模ジョブ
job_cpu    = "4000m"   # 4 vCPU
job_memory = "4Gi"     # 4GB
job_timeout = "3600s"  # 1時間
```

### 並列実行設定

```hcl
# 単一タスク実行
job_task_count = 1

# 10個の並列タスク実行
job_task_count = 10
```

## 運用コマンド

デプロイ後、以下のコマンドで運用できます：

### 手動でワークフローを実行

```bash
# Terraform outputから取得
terraform output trigger_workflow_command

# または直接実行
gcloud workflows execute workflow-batch-{env}-workflow \
  --location=asia-northeast1
```

### 手動でジョブを実行（Workflows経由せずに）

```bash
# Terraform outputから取得
terraform output trigger_job_command

# または直接実行
gcloud run jobs execute workflow-batch-{env}-job \
  --region=asia-northeast1
```

### ワークフロー実行履歴の確認

```bash
# Terraform outputから取得
terraform output list_executions_command

# または直接実行
gcloud workflows executions list workflow-batch-{env}-workflow \
  --location=asia-northeast1
```

### ジョブログの確認

```bash
# Terraform outputから取得
terraform output view_logs_command

# または直接実行
gcloud logging read \
  'resource.type=cloud_run_job AND resource.labels.job_name=workflow-batch-{env}-job' \
  --limit 50 --format json
```

### スケジュール一時停止

```bash
# スケジュールを一時停止
gcloud scheduler jobs pause workflow-batch-{env}-trigger \
  --location=asia-northeast1

# スケジュールを再開
gcloud scheduler jobs resume workflow-batch-{env}-trigger \
  --location=asia-northeast1
```

## カスタマイズ

### バッチジョブの実装

Cloud Run Jobで実行するコンテナは、以下の要件を満たす必要があります：

```dockerfile
# Dockerfile例
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# バッチ処理のエントリーポイント
CMD ["python", "batch_job.py"]
```

```python
# batch_job.py例
import os
import logging

# 環境変数の取得
PROJECT_ID = os.environ.get('PROJECT_ID')
ENVIRONMENT = os.environ.get('ENVIRONMENT')

def main():
    logging.info(f"Starting batch job in {ENVIRONMENT}")

    # バッチ処理ロジック
    # ...

    logging.info("Batch job completed successfully")

if __name__ == "__main__":
    main()
```

### 環境変数の設定

```hcl
job_env_vars = {
  LOG_LEVEL  = "info"
  BATCH_SIZE = "1000"
  DB_HOST    = "10.x.x.x"
}
```

### VPC接続（オプション）

プライベートリソースにアクセスする場合：

1. `cloudrun-job.tf`のVPCアクセス設定をコメント解除
2. VPC Connectorを作成
3. `vpc_connector`変数を追加して設定

## トラブルシューティング

### ワークフローが失敗する

```bash
# 1. ワークフロー実行詳細を確認
gcloud workflows executions describe EXECUTION_ID \
  --workflow=workflow-batch-{env}-workflow \
  --location=asia-northeast1

# 2. ワークフローログを確認
gcloud logging read \
  'resource.type="workflows.googleapis.com/Workflow"' \
  --limit 50 --format json
```

### ジョブが失敗する

```bash
# 1. ジョブ実行詳細を確認
gcloud run jobs executions describe EXECUTION_ID \
  --job=workflow-batch-{env}-job \
  --region=asia-northeast1

# 2. ジョブログを確認
gcloud logging read \
  'resource.type=cloud_run_job AND resource.labels.job_name=workflow-batch-{env}-job' \
  --limit 50 --format json
```

### スケジュールがトリガーされない

```bash
# スケジュール状態を確認
gcloud scheduler jobs describe workflow-batch-{env}-trigger \
  --location=asia-northeast1

# スケジュールログを確認
gcloud logging read \
  'resource.type=cloud_scheduler_job' \
  --limit 50
```

### 権限エラー

```bash
# Service Accountの権限を確認
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*workflow-batch*"
```

## コスト見積もり

### 開発環境（1日1回実行、10分/回）

| サービス | 月間使用量 | 概算コスト |
|---------|----------|----------|
| Cloud Scheduler | 1 job | $0.10 |
| Workflows | 30 executions | $0.00 |
| Cloud Run Job (1vCPU, 512MB) | 300 minutes | $1.50 |
| **合計** | | **$1.60/月** |

### 本番環境（1日1回実行、1時間/回、4vCPU）

| サービス | 月間使用量 | 概算コスト |
|---------|----------|----------|
| Cloud Scheduler | 1 job | $0.10 |
| Workflows | 30 executions | $0.00 |
| Cloud Run Job (4vCPU, 4GB) | 1,800 minutes | $36.00 |
| Cloud Monitoring | アラート | $1.00 |
| **合計** | | **$37.10/月** |

*価格は概算です。最新の料金は[GCP料金ページ](https://cloud.google.com/pricing)をご確認ください。*

## セキュリティ考慮事項

1. **最小権限の原則**: 各Service Accountは必要最小限の権限のみを付与
2. **Secret管理**: 機密情報はSecret Managerを使用（環境変数として直接設定しない）
3. **VPC**: プライベートリソースへのアクセスはVPC Connector経由
4. **監査ログ**: すべてのリソースでCloud Auditログを有効化

## 参考資料

- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs)
- [Workflows Documentation](https://cloud.google.com/workflows/docs)
- [Cloud Run Jobs Documentation](https://cloud.google.com/run/docs/create-jobs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## ライセンス

MIT License
