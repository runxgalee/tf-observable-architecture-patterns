# Secret Manager 移行ガイド

このガイドでは、GitHub ActionsのシークレットをGCP Secret Managerに移行する手順を説明します。

## 移行の目的

GitHub SecretsからGCP Secret Managerへの移行により、以下のメリットがあります：

1. **セキュリティ強化**: GCPのIAMによる厳密なアクセス制御
2. **監査ログ**: Cloud Audit Logsによる全アクセスの記録
3. **環境分離**: dev/prod環境ごとに異なるシークレット値を管理
4. **ローテーション**: シークレットのバージョン管理と自動ローテーション
5. **一元管理**: GCPリソースと同じプラットフォームで管理

## 移行対象のシークレット

| シークレット | 移行状況 | 理由 |
|------------|----------|------|
| `WIF_PROVIDER` | **GitHub Secretのまま** | 認証に必要（ブートストラップ用） |
| `WIF_SERVICE_ACCOUNT` | **GitHub Secretのまま** | 認証に必要 |
| `GCP_PROJECT_ID` | **新規追加** | Secret Managerアクセスに必要 |
| `TF_STATE_BUCKET` | **Secret Managerへ移行** | 環境別管理が必要 |

## 前提条件

- Workload Identity Federationが設定済み（`bootstrap/gcp/github-actions-auth/`）
- GitHub Actionsサービスアカウントが作成済み
- Secret Manager APIが有効化されている

## 移行手順

### ステップ1: Secret Manager APIの有効化

```bash
gcloud services enable secretmanager.googleapis.com \
  --project=your-gcp-project-id
```

### ステップ2: Secret Managerモジュールのデプロイ

```bash
# モジュールディレクトリに移動
cd bootstrap/gcp/github-actions-secrets

# 設定ファイルを作成
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`を編集：

```hcl
project_id            = "your-gcp-project-id"
service_account_email = "github-actions-terraform@your-project.iam.gserviceaccount.com"
environments          = ["dev", "prod"]

# 初期値を設定（既存のGitHub Secretsから値をコピー）
wif_service_account_values = {
  dev  = "github-actions-terraform@your-project.iam.gserviceaccount.com"
  prod = "github-actions-terraform@your-project.iam.gserviceaccount.com"
}

tf_state_bucket_values = {
  dev  = "your-terraform-state-bucket"
  prod = "your-terraform-state-bucket"
}
```

Terraformを適用：

```bash
terraform init
terraform plan
terraform apply
```

### ステップ3: シークレット値の確認

Secret Managerにシークレットが作成されたことを確認：

```bash
# シークレット一覧を表示
gcloud secrets list \
  --project=your-gcp-project-id \
  --filter="labels.purpose=github-actions"

# 特定のシークレット値を確認
gcloud secrets versions access latest \
  --secret="github-actions-dev-tf-state-bucket" \
  --project=your-gcp-project-id
```

### ステップ4: 新しいGitHub Secretの追加

GitHubリポジトリの Settings > Secrets and variables > Actions で以下を追加：

- **Name**: `GCP_PROJECT_ID`
- **Value**: `your-gcp-project-id`

### ステップ5: テスト実行

ワークフローを手動でトリガーしてテスト：

1. GitHubリポジトリの Actions タブを開く
2. "Terraform Apply on Main" ワークフローを選択
3. "Run workflow" をクリック
4. アーキテクチャと環境を選択（例: event-driven / dev）
5. "Run workflow" を実行

ワークフローログで以下を確認：
- ✅ Secret Managerからシークレット取得成功
- ✅ Terraform Init成功
- ✅ Terraform Apply成功

### ステップ6: 段階的なロールアウト

全てのワークフローが正常に動作することを確認後、以下の順で本番環境にロールアウト：

1. **Week 1**: dev環境での動作確認
   - 複数回のデプロイで安定性を確認
   - Secret Managerのアクセスログを確認

2. **Week 2**: prod環境での動作確認
   - 慎重にデプロイを実行
   - 問題があればすぐにロールバック可能

3. **Week 3**: GitHub Secretsのクリーンアップ（オプション）
   - `TF_STATE_BUCKET` シークレットを削除
   - `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`, `GCP_PROJECT_ID` は保持

## トラブルシューティング

### Secret Managerアクセス拒否エラー

```
Error: Failed to access secret: Permission 'secretmanager.versions.access' denied
```

**原因**: サービスアカウントにSecret Accessor権限がない

**解決策**:
```bash
# IAMポリシーを確認
gcloud secrets get-iam-policy github-actions-dev-tf-state-bucket \
  --project=your-gcp-project-id

# 権限を追加（必要に応じて）
gcloud secrets add-iam-policy-binding github-actions-dev-tf-state-bucket \
  --member="serviceAccount:github-actions-terraform@your-project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=your-gcp-project-id
```

### シークレットが見つからないエラー

```
Error: Secret not found: github-actions-dev-tf-state-bucket
```

**原因**: シークレットが作成されていない、または名前が間違っている

**解決策**:
```bash
# シークレット一覧を確認
gcloud secrets list --project=your-gcp-project-id

# 必要に応じてシークレットを作成
echo -n "your-bucket-name" | gcloud secrets create github-actions-dev-tf-state-bucket \
  --data-file=- \
  --project=your-gcp-project-id
```

### 認証エラー

```
Error: Unable to authenticate to Google Cloud
```

**原因**: WIF_PROVIDER または WIF_SERVICE_ACCOUNT が設定されていない

**解決策**:
- GitHub SecretsでWIF_PROVIDERとWIF_SERVICE_ACCOUNTが正しく設定されているか確認
- Workload Identity Federationの設定を再確認（`bootstrap/gcp/github-actions-auth/`）

## ロールバック手順

問題が発生した場合、以下の手順で元の状態に戻せます：

1. **ワークフローの修正**:
   ```yaml
   # .github/workflows/terraform-apply.yml
   # Secret Managerの取得ステップをコメントアウト

   # - name: Get secrets from Secret Manager
   #   id: secrets
   #   uses: google-github-actions/get-secretmanager-secrets@v3
   #   ...

   # Terraform Initを元に戻す
   - name: Terraform Init
     run: |
       terraform init \
         -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
         -backend-config="prefix=terraform/${{ matrix.pattern }}/${{ matrix.environment }}"
   ```

2. **変更をコミット・プッシュ**:
   ```bash
   git add .github/workflows/
   git commit -m "Rollback to GitHub Secrets"
   git push origin main
   ```

3. **Secret Managerリソースの保持**:
   - Secret Managerのシークレットは削除せず保持
   - 次回の移行時に再利用可能

## シークレット管理のベストプラクティス

### 1. シークレットのローテーション

定期的にシークレット値を更新：

```bash
# 新しいバージョンを追加
echo -n "new-bucket-name" | gcloud secrets versions add github-actions-dev-tf-state-bucket \
  --data-file=- \
  --project=your-gcp-project-id

# 古いバージョンを無効化（オプション）
gcloud secrets versions disable 1 \
  --secret="github-actions-dev-tf-state-bucket" \
  --project=your-gcp-project-id
```

### 2. アクセス監査

Cloud Audit Logsでシークレットアクセスを監視：

```bash
# 最近のシークレットアクセスログを確認
gcloud logging read "resource.type=secretmanager.googleapis.com/Secret \
  AND protoPayload.methodName=google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion" \
  --limit=50 \
  --format=json \
  --project=your-gcp-project-id
```

### 3. 最小権限の原則

サービスアカウントには必要最小限の権限のみを付与：
- ✅ `roles/secretmanager.secretAccessor` (シークレット読み取り)
- ❌ `roles/secretmanager.admin` (管理者権限は不要)

### 4. 環境分離

dev/prod環境で異なるシークレット値を使用：
- Dev: 開発用のバケット、低コストのリソース
- Prod: 本番用のバケット、高可用性のリソース

## コスト見積もり

Secret Managerの料金：
- **シークレット保存**: $0.06/シークレット/月
- **アクセス**: $0.03/10,000アクセス

**例**: 4シークレット、月間1000アクセスの場合
- 保存: 4 × $0.06 = $0.24/月
- アクセス: 1000 / 10000 × $0.03 = $0.003/月
- **合計**: 約 $0.25/月

## 次のステップ

- [ ] 全環境でSecret Managerの動作確認完了
- [ ] Cloud Audit Logsの監視設定
- [ ] シークレットローテーションの自動化検討
- [ ] 他のアプリケーションシークレットの移行検討

## 参考リンク

- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [google-github-actions/get-secretmanager-secrets](https://github.com/google-github-actions/get-secretmanager-secrets)
- [Secret Manager Pricing](https://cloud.google.com/secret-manager/pricing)
- [Best Practices for Secret Management](https://cloud.google.com/secret-manager/docs/best-practices)
