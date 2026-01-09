# GitOps Setup Guide

このドキュメントでは、GitHub ActionsでTerraform GitOpsを設定する方法を説明します。

## 概要

mainブランチへのマージ時に、変更があったpatternsのみ自動的にTerraform applyが実行されます。

## ワークフロー

複数のワークフローが用意されています：

### CI/テストワークフロー

#### `terraform-ci.yml` - CI/バリデーション（自動実行）
Pull RequestおよびmainブランチへのpushでTerraformコードの品質チェックを実行：

- **Format Check**: コードフォーマットの検証
- **Validate**: Terraform構文の検証
- **TFLint**: Terraformのベストプラクティスチェック
- **Documentation Check**: 必須ファイルの存在確認
- **Security Scan**: Trivyによるセキュリティスキャン
- **Syntax Test**: 全モジュールの構文テスト

#### `terraform-plan-pr.yml` - Pull Request時のPlan
- PR作成時にterraform planを自動実行
- 実行結果をPRにコメント表示
- 変更内容の事前確認が可能

### デプロイワークフロー

#### `terraform-apply.yml` - 自動デプロイ
- mainブランチへのpush時にトリガー
- **バリデーション**: fmt、validate、tflintを実行
- dev/prod環境を並列で自動apply
- 高速だが本番環境への自動デプロイあり

#### `terraform-apply-with-approval.yml` - 承認付きデプロイ（推奨）
- mainブランチへのpush時にトリガー
- **バリデーション**: fmt、validate、tflintを実行
- dev環境を先にapply
- prod環境へのapplyには手動承認が必要
- より安全な運用が可能

## セットアップ手順

### 1. GCP Workload Identity Federationの設定

GitHub ActionsからGCPにアクセスするため、Workload Identity Federationを設定します。

```bash
# プロジェクトIDを設定
export PROJECT_ID="your-gcp-project-id"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export GITHUB_ORG="your-github-org"
export GITHUB_REPO="your-github-repo"

# Workload Identity Poolの作成
gcloud iam workload-identity-pools create "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Workload Identity Providerの作成
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# サービスアカウントの作成
gcloud iam service-accounts create github-actions-terraform \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Terraform"

# サービスアカウントに権限を付与
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Workload Identity Federationの紐付け
gcloud iam service-accounts add-iam-policy-binding \
  "github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# Workload Identity Provider のリソース名を取得
gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

### 2. GitHub Secretsの設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下のsecretsを追加：

- `WIF_PROVIDER`: Workload Identity Providerのフルパス
  ```
  projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
  ```

- `WIF_SERVICE_ACCOUNT`: サービスアカウントのメールアドレス
  ```
  github-actions-terraform@PROJECT_ID.iam.gserviceaccount.com
  ```

- `GCP_PROJECT_ID`: GCPプロジェクトID（Secret Manager アクセスに必要）
  ```
  your-gcp-project-id
  ```

### 2.5. Secret Managerの設定（推奨）

環境固有のシークレットをGCP Secret Managerで管理することで、セキュリティと監査性が向上します。

**セットアップ手順:**

```bash
# Secret Managerモジュールのディレクトリに移動
cd bootstrap/gcp/github-actions-secrets

# 設定ファイルを作成
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvarsを編集し、以下を設定:
# - project_id: GCPプロジェクトID
# - service_account_email: GitHub Actionsサービスアカウントのメール
# - wif_service_account_values: 各環境のサービスアカウント
# - tf_state_bucket_values: 各環境のTerraformステートバケット名

# Terraformを初期化して適用
terraform init
terraform plan
terraform apply
```

詳細は `bootstrap/gcp/github-actions-secrets/README.md` を参照してください。

**Secret Managerで管理されるシークレット:**
- `github-actions-dev-tf-state-bucket`: Dev環境のTerraformステートバケット名
- `github-actions-prod-tf-state-bucket`: Prod環境のTerraformステートバケット名

ワークフローは自動的にこれらのシークレットを取得して使用します。

### 3. 本番環境の承認設定（terraform-apply-with-approval.ymlを使用する場合）

GitHubリポジトリの Settings > Environments で環境を設定：

1. "New environment" をクリック
2. 環境名: `production`
3. "Required reviewers" を有効化
4. 承認者を追加

### 4. Terraform Backendの設定

各環境のbackend.tfファイルでGCS backendを設定：

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "architectures/pattern-name/environment-name"
  }
}
```

### 5. ワークフローの選択

使用するワークフローを選択：

**承認付きデプロイ（推奨）:**
- `terraform-apply-with-approval.yml` を使用
- `terraform-apply.yml` を削除またはリネーム

**自動デプロイ:**
- `terraform-apply.yml` を使用
- `terraform-apply-with-approval.yml` を削除またはリネーム

## 動作の仕組み

### 変更検出

ワークフローは以下のロジックで変更を検出します：

1. 前回のコミットとの差分を取得
   ```bash
   git diff --name-only HEAD~1 HEAD
   ```

2. `patterns/` 配下の変更ファイルを抽出

3. パターン名を抽出
   ```bash
   grep '^architectures/' | cut -d'/' -f2 | sort -u
   ```

4. 変更があったパターンのみをmatrix strategyで実行

### 実行フロー

```
mainへのpush
  ↓
変更検出ジョブ
  ↓
変更されたpatternsを特定
  ↓
各pattern × 各環境でTerraform Apply
```

## トラブルシューティング

### 認証エラー

```
Error: google: could not find default credentials
```

**解決策:**
- WIF_PROVIDERとWIF_SERVICE_ACCOUNTが正しく設定されているか確認
- サービスアカウントに必要な権限があるか確認

### 変更が検出されない

**確認項目:**
- 変更したファイルが `patterns/` 配下にあるか
- コミットがmainブランチにマージされているか

### Terraform Init失敗

```
Error: Failed to get existing workspaces
```

**解決策:**
- GCS backendのバケットが存在するか確認
- サービスアカウントにバケットへのアクセス権限があるか確認

## ローカル開発とテスト

### ローカルでのバリデーション

コミット前にローカルでバリデーションを実行できます：

```bash
# 特定のパターンを検証
./scripts/validate-pattern.sh event-driven

# 全パターンを検証
./scripts/validate-all.sh

# 変更されたパターンを検出
./scripts/detect-changed-architectures.sh
```

### Pre-commitフックの設定

コミット時に自動でバリデーションを実行：

```bash
# Pre-commitフックをインストール
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# テスト
git add .
git commit -m "test"  # 自動的にバリデーションが実行される
```

### TFLintのローカル実行

```bash
# TFLintのインストール（macOS）
brew install tflint

# TFLintのインストール（Linux）
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# 特定のパターンでTFLintを実行
cd architectures/event-driven/gcp
tflint --init
tflint

# 全モジュールでTFLintを実行
cd modules
for module in */; do
  cd "$module"
  tflint --init
  tflint
  cd ..
done
```

### コードフォーマット

```bash
# 全ファイルをフォーマット
terraform fmt -recursive

# 特定のパターンのみフォーマット
cd architectures/event-driven/gcp
terraform fmt -recursive

# フォーマットチェックのみ（変更しない）
terraform fmt -check -recursive
```

## ベストプラクティス

1. **Pull Requestでのplan確認**
   - `terraform-plan-pr.yml` が自動的にterraform planを実行
   - PRマージ前に変更内容を確認

2. **State管理**
   - GCS backendで状態を一元管理
   - バケットのバージョニングを有効化
   - State lockingを有効化

3. **環境分離**
   - 環境ごとに異なるGCPプロジェクトを使用
   - 環境ごとに異なるサービスアカウントを使用
   - State管理も環境ごとに分離

4. **監視とアラート**
   - GitHub Actions実行結果をSlackなどに通知
   - Terraformの変更をログ管理
   - セキュリティスキャン結果を定期確認

5. **コード品質**
   - Pre-commitフックでローカル検証を徹底
   - TFLintでベストプラクティスを遵守
   - 定期的なセキュリティスキャン実行

## 次のステップ

- [x] Pull Request時のterraform planワークフロー（完了）
- [x] CI/バリデーションワークフロー（完了）
- [x] TFLint設定（完了）
- [x] ローカルバリデーションスクリプト（完了）
- [ ] Slack/Discord通知の設定
- [ ] drift detectionの設定（定期的なterraform plan実行）
- [ ] コスト見積もりの自動化（Infracost統合）
