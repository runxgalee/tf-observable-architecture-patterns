# Microservices on GKE Autopilot - GCP Implementation

GKE Autopilot + Ingress + Workload Identity を使用したマイクロサービスアーキテクチャの実装

## アーキテクチャ概要

このパターンは、Google Kubernetes Engine (GKE) Autopilot を使用して、スケーラブルで安全なマイクロサービスアーキテクチャを構築します。

### 主要コンポーネント

- **GKE Autopilot**: フルマネージドKubernetesクラスタ（ノード管理不要）
- **Ingress (HTTPS Load Balancer)**: Google Cloud Load Balancer による外部アクセス
- **Workload Identity**: GCPサービスへの安全なアクセス
- **Managed SSL**: Google管理のSSL証明書
- **Cloud Monitoring**: 包括的な監視とアラート
- **Kustomize**: 環境別のマニフェスト管理

### アーキテクチャ図

```
Internet
    |
    v
[Google Cloud Load Balancer]
    |
    v
[Managed SSL Certificate]
    |
    v
[GKE Ingress]
    |
    +-- [Frontend Service] --> [Frontend Pods (3+ replicas)]
    |                              |
    |                              v
    |                          [Workload Identity]
    |                              |
    |                              v
    +-- [Backend Service] --> [Backend Pods (3+ replicas)]
                                   |
                                   v
                              [Workload Identity]
                                   |
                                   v
                           [Cloud SQL, Secret Manager, etc.]
```

## 主な機能

### セキュリティ

- **Private GKE Cluster**: ノードはプライベートIPのみ
- **Workload Identity**: サービスアカウントキー不要の安全な認証
- **Binary Authorization**: 署名済みコンテナイメージのみデプロイ（本番環境）
- **Shielded GKE Nodes**: セキュアブート、vTPM、整合性モニタリング
- **Network Policies**: Pod間通信の制御（オプション）

### スケーラビリティ

- **Autopilot Auto-scaling**: ワークロードに応じた自動スケール
- **Horizontal Pod Autoscaler**: CPU/メモリ使用量に基づく Pod スケール
- **Multi-zone Deployment**: 複数ゾーンでの高可用性

### 監視・運用

- **Cloud Monitoring**: メトリクス収集と可視化
- **Cloud Logging**: 構造化ログ
- **Alert Policies**: Pod再起動、リソース使用率、ヘルスチェック失敗
- **Uptime Checks**: Ingress エンドポイントの死活監視

### 環境分離

- **dev環境**: コスト最適化、緩いセキュリティ
- **prod環境**: 高可用性、厳格なセキュリティ、Binary Authorization

## ディレクトリ構造

```
patterns/02-microservices-gke/
├── gcp/
│   ├── README.md (このファイル)
│   ├── modules/
│   │   └── microservices-gke/
│   │       ├── versions.tf
│   │       ├── main.tf
│   │       ├── gke.tf
│   │       ├── iam.tf
│   │       ├── monitoring.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── dev/
│       │   ├── providers.tf
│       │   ├── backend.tf
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── terraform.tfvars.example
│       └── prod/
│           ├── providers.tf
│           ├── backend.tf
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
└── k8s/
    ├── base/
    │   ├── backend-deployment.yaml
    │   ├── backend-service.yaml
    │   ├── frontend-deployment.yaml
    │   ├── frontend-service.yaml
    │   ├── ingress.yaml
    │   └── kustomization.yaml
    └── overlays/
        ├── dev/
        │   ├── kustomization.yaml
        │   └── replica-patch.yaml
        └── prod/
            ├── kustomization.yaml
            ├── replica-patch.yaml
            └── resource-patch.yaml
```

## クイックスタート

### 前提条件

1. **Google Cloud SDK** インストール済み
2. **Terraform >= 1.0** インストール済み
3. **kubectl** インストール済み
4. **GCPプロジェクト** 作成済み
5. **必要なAPI有効化**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable monitoring.googleapis.com
   gcloud services enable logging.googleapis.com
   ```

### 開発環境のデプロイ

#### 1. Terraformで GKE クラスタをデプロイ

```bash
# 環境ディレクトリに移動
cd architectures/microservices-gke/gcp/environments/dev

# 設定ファイルの準備
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars を編集して project_id を設定
vim terraform.tfvars

# Terraformの実行
terraform init
terraform plan
terraform apply

# 出力の確認
terraform output
```

#### 2. kubectl の設定

```bash
# Terraform output から kubectl 設定コマンドを取得して実行
gcloud container clusters get-credentials dev-microservices-microservices \
  --region=asia-northeast1 \
  --project=your-project-id
```

#### 3. Workload Identity の設定

Kubernetes マニフェストに Service Account のメールアドレスを設定:

```bash
# Terraform output から Service Account のメールアドレスを取得
terraform output service_accounts

# k8s マニフェストを更新
cd ../../../k8s/base

# backend-deployment.yaml を編集
# BACKEND_SA_EMAIL を実際のメールアドレスに置換

# frontend-deployment.yaml を編集
# FRONTEND_SA_EMAIL を実際のメールアドレスに置換
```

#### 4. Ingress の設定

```bash
# Terraform output から Ingress IP 名を取得
terraform output ingress_ip_address

# ingress.yaml を編集
# INGRESS_IP_NAME を実際のIP名に置換（例: dev-microservices-ingress-ip）
# DOMAIN_NAME を実際のドメインに置換（または削除）
```

#### 5. Kubernetes リソースのデプロイ

```bash
# dev環境のマニフェストをデプロイ
kubectl apply -k overlays/dev

# デプロイ状況の確認
kubectl get pods
kubectl get services
kubectl get ingress
```

#### 6. アクセス確認

```bash
# Ingress の外部IPアドレスを確認
kubectl get ingress frontend-ingress

# ブラウザまたはcurlでアクセス
curl http://<EXTERNAL-IP>
```

### 本番環境のデプロイ

#### 1. State管理用のGCSバケット作成

```bash
gcloud storage buckets create gs://your-terraform-state-bucket \
  --project=your-prod-project-id \
  --location=asia-northeast1 \
  --uniform-bucket-level-access
```

#### 2. backend.tf の設定

```bash
cd architectures/microservices-gke/gcp/environments/prod

# backend.tf を編集してバケット名を設定
vim backend.tf
```

#### 3. terraform.tfvars の設定

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 以下を設定:
# - project_id
# - ssl_certificate_domains (本番ドメイン)
# - master_authorized_networks (許可するネットワーク)
# - notification_channels (アラート通知先)
```

#### 4. Terraform の実行

```bash
terraform init
terraform plan
terraform apply
```

#### 5. Kubernetes リソースのデプロイ

dev環境と同様の手順で、`kubectl apply -k overlays/prod` を実行

## 環境別設定の違い

| 設定項目 | dev | prod |
|---------|-----|------|
| Release Channel | REGULAR | STABLE |
| Binary Authorization | 無効 | 有効 |
| Frontend Replicas | 2 | 5 |
| Backend Replicas | 2 | 5 |
| CPU Requests | 250m | 500m |
| Memory Requests | 256Mi | 512Mi |
| CPU Limits | 500m | 1000m |
| Memory Limits | 512Mi | 1Gi |
| Pod Restart Threshold | 5 | 3 |
| Node CPU Threshold | 80% | 75% |
| Managed SSL | オプション | 有効 |
| Deletion Protection | 無効 | 有効 |

## 運用

### ログの確認

```bash
# Pod ログの確認
kubectl logs -f deployment/frontend
kubectl logs -f deployment/backend

# Cloud Loggingでの確認
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=dev-microservices-microservices" \
  --limit 50 \
  --format json
```

### メトリクスの確認

```bash
# Cloud Monitoring でメトリクスを確認
# https://console.cloud.google.com/monitoring

# kubectl top コマンドでリソース使用量を確認
kubectl top nodes
kubectl top pods
```

### スケーリング

```bash
# 手動スケール
kubectl scale deployment frontend --replicas=5
kubectl scale deployment backend --replicas=5

# HPA (Horizontal Pod Autoscaler) の設定
kubectl autoscale deployment frontend --cpu-percent=70 --min=3 --max=10
kubectl autoscale deployment backend --cpu-percent=70 --min=3 --max=10

# HPA の確認
kubectl get hpa
```

### ローリングアップデート

```bash
# イメージの更新
kubectl set image deployment/frontend frontend=gcr.io/your-project/frontend:v2.0
kubectl set image deployment/backend backend=gcr.io/your-project/backend:v2.0

# ロールアウト状況の確認
kubectl rollout status deployment/frontend
kubectl rollout status deployment/backend

# ロールバック
kubectl rollout undo deployment/frontend
```

### SSL証明書の確認

```bash
# Managed Certificate の状態確認
kubectl describe managedcertificate frontend-ssl-cert

# 証明書のプロビジョニングには最大15分かかる場合があります
```

## トラブルシューティング

### Pod が Pending 状態

```bash
# Pod の詳細を確認
kubectl describe pod <pod-name>

# イベントログを確認
kubectl get events --sort-by='.lastTimestamp'

# ノードのリソースを確認（Autopilotは自動スケールするが、制限がある場合あり）
kubectl top nodes
```

### Ingress の IP アドレスが割り当てられない

```bash
# Ingress の状態確認
kubectl describe ingress frontend-ingress

# BackendConfig の確認
kubectl describe backendconfig frontend-backendconfig

# 通常、IPアドレスの割り当てには5-10分かかります
```

### Workload Identity が機能しない

```bash
# Service Account の確認
kubectl describe serviceaccount backend-sa

# Annotationが正しく設定されているか確認
kubectl get serviceaccount backend-sa -o yaml

# IAM binding の確認
gcloud iam service-accounts get-iam-policy \
  dev-microservices-backend@your-project-id.iam.gserviceaccount.com
```

### SSL証明書がプロビジョニングされない

```bash
# ManagedCertificate の状態確認
kubectl describe managedcertificate frontend-ssl-cert

# DNSレコードが正しく設定されているか確認
dig <your-domain>

# ドメインがIngress IPを指していることを確認
```

## コスト最適化

### 開発環境

- **Autopilot**: 実際に使用したリソースのみ課金
- **少ないレプリカ数**: dev は 2 replicas
- **小さいリソース要求**: CPU 250m, Memory 256Mi

### 本番環境

- **Reserved Resources**: 長期コミットメント割引を検討
- **Autoscaling**: HPA でピーク時のみスケール
- **Regional Cluster**: Multi-zonal より低コスト（可用性は下がる）

### コスト見積もり（月額）

| 環境 | 概算コスト |
|------|-----------|
| dev  | $100-150  |
| prod | $300-500  |

*実際のコストはリソース使用量、トラフィック、リージョンによって変動します*

## セキュリティベストプラクティス

1. **Private Cluster**: ノードはプライベートIPのみ
2. **Master Authorized Networks**: APIサーバーへのアクセス制限
3. **Workload Identity**: サービスアカウントキーを使用しない
4. **Binary Authorization**: 署名済みイメージのみデプロイ（本番）
5. **Shielded Nodes**: セキュアブート有効化
6. **Network Policies**: Pod間通信の制御
7. **Secret Manager**: 機密情報の安全な管理
8. **定期的なアップデート**: Release Channel でセキュリティパッチを自動適用

## 参考資料

- [GKE Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Workload Identity Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GKE Ingress for HTTPS Load Balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)
- [Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
