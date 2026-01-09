# イベント駆動アーキテクチャ 設計書

## 1. 概要

### 1.1 目的
非同期メッセージング基盤を使用したスケーラブルなイベント駆動型システムの構築

### 1.2 対象システム
- **パターン名**: Event-Driven Architecture
- **主要コンポーネント**: メッセージキュー、サーバーレスコンピュート
- **ユースケース**:
  - 非同期処理が必要なワークフロー
  - マイクロサービス間の疎結合な連携
  - イベントソーシング、CQRS パターンの実装

## 2. アーキテクチャ設計

### 2.1 GCP実装

#### コンポーネント構成

```
┌─────────────┐
│  Publisher  │ (アプリケーション、外部システム等)
└──────┬──────┘
       │ publish message
       ▼
┌─────────────────┐
│   Pub/Sub Topic │ (イベントトピック)
└────────┬────────┘
         │ push subscription
         ▼
┌──────────────────┐
│   Cloud Run      │ (イベント処理)
│   - Consumer 1   │
│   - Consumer 2   │
│   - Consumer N   │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│  Backend Services│ (データベース、API等)
└──────────────────┘
```

#### 主要リソース

| リソース | 用途 | 備考 |
|---------|------|------|
| **Pub/Sub Topic** | イベントメッセージの配信 | メッセージの永続化と配信保証 |
| **Pub/Sub Subscription** | メッセージの購読設定 | Push型でCloud Runにメッセージ送信 |
| **Cloud Run Service** | イベント処理ロジックの実行 | コンテナベースのサーバーレス実行環境 |
| **Service Account** | 権限管理 | 最小権限の原則に基づく設定 |
| **Secret Manager** | 機密情報管理 | API キー、DB 接続情報等 |

#### メッセージフロー

1. **Publisher** が Pub/Sub Topic にメッセージを発行
2. **Pub/Sub** がメッセージを永続化し、Subscription 経由で配信
3. **Cloud Run** が HTTP POST でメッセージを受信
4. **Cloud Run** が処理を実行し、成功/失敗を応答
5. 失敗時は **Pub/Sub** が自動的に再試行（exponential backoff）

### 2.2 AWS実装（マルチクラウド対応）

#### コンポーネント構成

```
┌─────────────┐
│  Publisher  │
└──────┬──────┘
       │ put events
       ▼
┌─────────────────┐
│  EventBridge    │ (イベントバス)
└────────┬────────┘
         │ rule trigger
         ▼
┌──────────────────┐
│   Lambda         │ (イベント処理)
│   - Consumer 1   │
│   - Consumer 2   │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│  Backend Services│
└──────────────────┘
```

#### 主要リソース

| リソース | 用途 | GCP相当 |
|---------|------|---------|
| **EventBridge Event Bus** | イベントルーティング | Pub/Sub Topic |
| **EventBridge Rule** | イベントフィルタリングとルーティング | Pub/Sub Subscription (フィルタ付き) |
| **Lambda Function** | イベント処理 | Cloud Run |
| **IAM Role** | 権限管理 | Service Account |
| **Secrets Manager** | 機密情報管理 | Secret Manager |

## 3. マルチクラウド設計の考慮事項

### 3.1 抽象化レイヤー

クラウドプロバイダー固有の機能に依存しないよう、以下の抽象化を行う：

- **イベント形式**: CloudEvents 標準形式を採用
- **認証・認可**: OIDCベースの認証（可能な限り）
- **モニタリング**: OpenTelemetry による統一的な監視

### 3.2 GCP vs AWS の対応表

| 機能 | GCP | AWS |
|------|-----|-----|
| メッセージング | Pub/Sub | EventBridge / SQS |
| サーバーレス実行 | Cloud Run | Lambda / ECS Fargate |
| コンテナレジストリ | Artifact Registry | ECR |
| シークレット管理 | Secret Manager | Secrets Manager |
| IAM | Service Account | IAM Role |
| ログ | Cloud Logging | CloudWatch Logs |
| メトリクス | Cloud Monitoring | CloudWatch Metrics |

### 3.3 移植性の確保

```
共通設定ファイル (variables)
        │
        ├─── GCP モジュール
        │     └── GCP固有リソース
        │
        └─── AWS モジュール
              └── AWS固有リソース
```

## 4. セキュリティ設計

### 4.1 認証・認可

**GCP:**
- Service Account による最小権限の原則
- Workload Identity による安全な認証
- Pub/Sub → Cloud Run は Push Subscription + JWT 検証

**AWS:**
- IAM Role による最小権限の原則
- Lambda 実行ロールの適切な設定
- EventBridge → Lambda は Resource-based Policy

### 4.2 ネットワークセキュリティ

**GCP:**
- Cloud Run: VPC Connector 経由でのプライベートネットワークアクセス
- Pub/Sub: VPC Service Controls による境界制御

**AWS:**
- Lambda: VPC 内での実行（必要に応じて）
- EventBridge: VPC エンドポイント経由のアクセス

### 4.3 暗号化

- **転送中**: TLS 1.2+ による暗号化（両環境）
- **保存時**: デフォルトの暗号化を使用
  - GCP: Google-managed encryption keys
  - AWS: AWS-managed keys (KMS)

## 5. スケーラビリティ設計

### 5.1 GCP

| コンポーネント | スケーリング方法 |
|--------------|----------------|
| Pub/Sub | 自動スケール（無制限） |
| Cloud Run | 同時実行数に応じた自動スケール（0-1000インスタンス） |

設定例:
```hcl
min_instances = 0  # コールドスタート許容
max_instances = 100
concurrency = 80   # コンテナあたりの同時リクエスト数
```

### 5.2 AWS

| コンポーネント | スケーリング方法 |
|--------------|----------------|
| EventBridge | 自動スケール（無制限） |
| Lambda | 同時実行数に応じた自動スケール（デフォルト1000） |

設定例:
```hcl
reserved_concurrent_executions = 100  # 同時実行数の上限
memory_size = 1024                     # メモリサイズ
timeout = 300                          # タイムアウト（秒）
```

## 6. 監視・運用設計

### 6.1 監視項目

**共通メトリクス:**
- メッセージ処理数（成功/失敗）
- 処理レイテンシ
- エラー率
- Dead Letter Queue のメッセージ数

**GCP固有:**
- Cloud Run のインスタンス数
- Cloud Run のリクエストカウント
- Pub/Sub の未確認メッセージ数

**AWS固有:**
- Lambda の呼び出し回数
- Lambda のエラー数
- Lambda の同時実行数

### 6.2 アラート設定

| 条件 | アクション |
|------|----------|
| エラー率 > 5% (5分間) | 通知 + エスカレーション |
| 処理遅延 > 1分 | 通知 |
| Dead Letter Queue にメッセージ蓄積 | 通知 |

### 6.3 ログ設計

**構造化ログフォーマット (JSON):**
```json
{
  "timestamp": "2025-12-21T00:00:00Z",
  "level": "INFO",
  "message": "Event processed successfully",
  "event_id": "abc-123",
  "trace_id": "xyz-789",
  "processing_time_ms": 150
}
```

## 7. コスト最適化

### 7.1 GCP コスト見積もり

**想定ワークロード**: 100万メッセージ/月

| サービス | 使用量 | 月額コスト（概算） |
|---------|--------|------------------|
| Pub/Sub | 100万メッセージ | $40 |
| Cloud Run | 100万リクエスト, 1vCPU, 512MB | $25 |
| Cloud Logging | 10GB | $5 |
| **合計** | | **$70** |

### 7.2 AWS コスト見積もり

**想定ワークロード**: 100万イベント/月

| サービス | 使用量 | 月額コスト（概算） |
|---------|--------|------------------|
| EventBridge | 100万イベント | $1 |
| Lambda | 100万リクエスト, 512MB, 3秒実行 | $20 |
| CloudWatch Logs | 10GB | $5 |
| **合計** | | **$26** |

### 7.3 コスト削減策

- **GCP**:
  - Cloud Run の min_instances = 0 でコールドスタートを許容
  - 長期ログは Cloud Storage にエクスポート
- **AWS**:
  - Lambda の適切なメモリサイズ設定（過剰割り当て回避）
  - CloudWatch Logs の保持期間を最適化

## 8. 実装フェーズ

### Phase 1: GCP 基本実装
- [x] Pub/Sub Topic 作成
- [x] Cloud Run サービス作成
- [x] Push Subscription 設定
- [x] 基本的な監視設定

### Phase 2: GCP 本番対応
- [ ] Dead Letter Queue 設定
- [ ] VPC Connector 設定
- [ ] Secret Manager 統合
- [ ] 詳細な監視・アラート設定

### Phase 3: AWS 実装
- [ ] EventBridge Event Bus 作成
- [ ] Lambda Function 作成
- [ ] EventBridge Rule 設定
- [ ] 監視設定

### Phase 4: マルチクラウド対応
- [ ] CloudEvents 形式の統一
- [ ] クロスクラウドイベント連携
- [ ] 統合モニタリング

## 9. 参考資料

### GCP
- [Cloud Pub/Sub ドキュメント](https://cloud.google.com/pubsub/docs)
- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)

### AWS
- [Amazon EventBridge ドキュメント](https://docs.aws.amazon.com/eventbridge/)
- [AWS Lambda ドキュメント](https://docs.aws.amazon.com/lambda/)

### 標準仕様
- [CloudEvents Specification](https://cloudevents.io/)
