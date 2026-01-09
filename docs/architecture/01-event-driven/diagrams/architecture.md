# Event-Driven Architecture Diagrams

## GCP アーキテクチャ図

### 基本構成

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Event Publishers                            │
│  (Applications, External Systems, Scheduled Jobs, etc.)             │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         │ publish message (JSON)
                         │
                         ▼
          ┌──────────────────────────────┐
          │    Pub/Sub Topic             │
          │    "dev-events"              │
          │                              │
          │  - Message Retention: 24h    │
          │  - Encryption: Google-managed│
          └──────────┬───────────────────┘
                     │
                     │ push subscription (HTTPS + OIDC)
                     │
                     ▼
          ┌──────────────────────────────┐
          │   Pub/Sub Subscription       │
          │   "dev-events-subscription"  │
          │                              │
          │  - Ack Deadline: 60s         │
          │  - Retry: Exponential Backoff│
          │  - Max Attempts: 5           │
          └──────────┬───────────────────┘
                     │
                     │ HTTP POST
                     │
                     ▼
          ┌──────────────────────────────┐
          │     Cloud Run Service        │
          │   "event-processor"          │
          │                              │
          │  - Min Instances: 0          │
          │  - Max Instances: 100        │
          │  - Concurrency: 80           │
          │  - CPU: 1 vCPU               │
          │  - Memory: 512Mi             │
          └──────────┬───────────────────┘
                     │
                     │ process event
                     │
        ┌────────────┴────────────┐
        │                         │
        │ Success (200)           │ Failure (4xx, 5xx)
        │                         │
        ▼                         ▼
   ┌─────────┐          ┌─────────────────┐
   │  ACK    │          │  NACK + Retry   │
   └─────────┘          └────────┬────────┘
                                 │
                                 │ after max attempts
                                 │
                                 ▼
                   ┌──────────────────────────┐
                   │  Dead Letter Topic       │
                   │  "dev-events-dead-letter"│
                   │                          │
                   │  ⚠️  Alert Triggered     │
                   └──────────────────────────┘
```

### セキュリティ層

```
┌─────────────────────────────────────────────────────────────┐
│                    IAM & Security                            │
└─────────────────────────────────────────────────────────────┘

Service Account: dev-event-processor@project.iam.gserviceaccount.com
  ├─ Cloud Run Execution Identity
  └─ Roles:
      └─ (Custom roles for backend services)

Service Account: dev-pubsub-invoker@project.iam.gserviceaccount.com
  ├─ Pub/Sub → Cloud Run Authentication
  └─ Roles:
      └─ roles/run.invoker (on Cloud Run service)

Google-managed Service Account: service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com
  └─ Roles:
      ├─ roles/pubsub.publisher (on dead letter topic)
      └─ roles/pubsub.subscriber (on main subscription)

Push Subscription Authentication:
  └─ OIDC Token with service account identity
```

### モニタリング構成

```
┌──────────────────────────────────────────────────────────────┐
│                    Cloud Monitoring                           │
└──────────────────────────────────────────────────────────────┘

Metrics:
  ├─ Pub/Sub
  │   ├─ pubsub.googleapis.com/subscription/num_undelivered_messages
  │   ├─ pubsub.googleapis.com/subscription/oldest_unacked_message_age
  │   └─ pubsub.googleapis.com/topic/send_request_count
  │
  └─ Cloud Run
      ├─ run.googleapis.com/request_count
      ├─ run.googleapis.com/request_latencies
      └─ run.googleapis.com/container/instance_count

Alerts:
  ├─ Dead Letter Queue Messages > 0 (5 min)
  ├─ Error Rate > 5% (5 min)
  └─ Undelivered Messages > 1000 (5 min)

Logs:
  ├─ Cloud Run Application Logs (stdout/stderr)
  ├─ Pub/Sub Delivery Logs
  └─ Structured JSON Logging
```

## AWS アーキテクチャ図（予定）

### 基本構成

```
┌─────────────────────────────────────────────────────────────┐
│                    Event Publishers                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ put events
                         │
                         ▼
          ┌──────────────────────────────┐
          │   EventBridge Event Bus      │
          │   "dev-events"               │
          │                              │
          │  - Retention: 24h            │
          │  - Encryption: AWS-managed   │
          └──────────┬───────────────────┘
                     │
                     │ event pattern match
                     │
                     ▼
          ┌──────────────────────────────┐
          │   EventBridge Rule           │
          │   "dev-event-rule"           │
          │                              │
          │  - Pattern: User events      │
          │  - Max Attempts: 5           │
          └──────────┬───────────────────┘
                     │
                     │ invoke
                     │
                     ▼
          ┌──────────────────────────────┐
          │   Lambda Function            │
          │   "event-processor"          │
          │                              │
          │  - Memory: 512MB             │
          │  - Timeout: 60s              │
          │  - Concurrency: 100          │
          └──────────┬───────────────────┘
                     │
                     │ process event
                     │
        ┌────────────┴────────────┐
        │                         │
        │ Success                 │ Failure
        │                         │
        ▼                         ▼
   ┌─────────┐          ┌─────────────────┐
   │Complete │          │  Retry          │
   └─────────┘          └────────┬────────┘
                                 │
                                 │ after max attempts
                                 │
                                 ▼
                   ┌──────────────────────────┐
                   │  Dead Letter Queue (SQS) │
                   │  "dev-events-dlq"        │
                   │                          │
                   │  ⚠️  Alarm Triggered     │
                   └──────────────────────────┘
```

## マルチクラウド比較

| 要素 | GCP | AWS |
|------|-----|-----|
| **メッセージング** | Pub/Sub Topic | EventBridge Event Bus |
| **サブスクリプション** | Push Subscription | EventBridge Rule |
| **コンピュート** | Cloud Run | Lambda |
| **認証** | Service Account + OIDC | IAM Role |
| **Dead Letter** | Dead Letter Topic | SQS DLQ |
| **モニタリング** | Cloud Monitoring | CloudWatch |
| **ログ** | Cloud Logging | CloudWatch Logs |

## データフロー

### メッセージフォーマット（CloudEvents標準）

```json
{
  "specversion": "1.0",
  "type": "com.example.user.created",
  "source": "https://api.example.com/users",
  "id": "A234-1234-1234",
  "time": "2025-12-21T12:00:00Z",
  "datacontenttype": "application/json",
  "data": {
    "userId": "12345",
    "email": "user@example.com",
    "createdAt": "2025-12-21T12:00:00Z"
  }
}
```

### GCP Pub/Sub メッセージ形式

```json
{
  "message": {
    "data": "base64-encoded-data",
    "messageId": "1234567890",
    "publishTime": "2025-12-21T12:00:00Z",
    "attributes": {
      "key1": "value1"
    }
  },
  "subscription": "projects/PROJECT_ID/subscriptions/SUBSCRIPTION_ID"
}
```

### AWS EventBridge イベント形式

```json
{
  "version": "0",
  "id": "1234567890",
  "detail-type": "User Created",
  "source": "custom.application",
  "account": "123456789012",
  "time": "2025-12-21T12:00:00Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "userId": "12345",
    "email": "user@example.com",
    "createdAt": "2025-12-21T12:00:00Z"
  }
}
```
