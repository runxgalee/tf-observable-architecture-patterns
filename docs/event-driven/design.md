# Event-Driven Architecture Design

## Overview

This document describes the design of the Event-Driven Architecture pattern implemented on Google Cloud Platform (GCP). The architecture enables asynchronous, scalable event processing using Pub/Sub and Cloud Run.

## Architecture Diagram

```
                                    GCP Project
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  ┌──────────────┐                                                           │
│  │   Service    │                                                           │
│  │  Accounts    │                                                           │
│  │ ┌──────────┐ │                                                           │
│  │ │Cloud Run │ │                                                           │
│  │ │   SA     │ │                                                           │
│  │ └──────────┘ │                                                           │
│  │ ┌──────────┐ │                                                           │
│  │ │ Pub/Sub  │ │                                                           │
│  │ │   SA     │ │                                                           │
│  │ └──────────┘ │                                                           │
│  └──────────────┘                                                           │
│                                                                             │
│                                                                             │
│  ┌─────────┐    ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐ │
│  │  Event  │    │   Pub/Sub   │    │     Push     │    │    Cloud Run    │ │
│  │ Producer│───▶│    Topic    │───▶│ Subscription │───▶│  Event Handler  │ │
│  │(External)    │             │    │  (OIDC Auth) │    │                 │ │
│  └─────────┘    └─────────────┘    └──────────────┘    └─────────────────┘ │
│                        │                  │                     │          │
│                        │                  │ (Failed)            │          │
│                        │                  ▼                     │          │
│                        │           ┌─────────────┐              │          │
│                        │           │ Dead Letter │              │          │
│                        │           │    Topic    │              │          │
│                        │           └─────────────┘              │          │
│                        │                  │                     │          │
│                        │                  ▼                     │          │
│                        │           ┌─────────────┐              │          │
│                        │           │     DLQ     │              │          │
│                        │           │Subscription │              │          │
│                        │           └─────────────┘              │          │
│                        │                  │                     │          │
│                        ▼                  ▼                     ▼          │
│                 ┌────────────────────────────────────────────────────┐     │
│                 │                  Observability                     │     │
│                 │  ┌──────────────┐  ┌─────────┐  ┌───────────────┐  │     │
│                 │  │   Cloud      │  │  Cloud  │  │     Cloud     │  │     │
│                 │  │  Monitoring  │  │ Logging │  │     Trace     │  │     │
│                 │  │  (Alerts)    │  │         │  │               │  │     │
│                 │  └──────────────┘  └─────────┘  └───────────────┘  │     │
│                 │                  Dashboard                         │     │
│                 └────────────────────────────────────────────────────┘     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Pub/Sub Topic

**Purpose**: Receives events from producers and distributes them to subscribers.

| Property | Configuration |
|----------|---------------|
| Message Retention | 24 hours (configurable) |
| Schema | None (flexible JSON) |
| Labels | environment, managed_by, project |

### 2. Push Subscription

**Purpose**: Delivers messages to Cloud Run via HTTP push with OIDC authentication.

| Property | Configuration |
|----------|---------------|
| Delivery Type | Push |
| Authentication | OIDC Token |
| Ack Deadline | 60 seconds (configurable) |
| Retry Policy | Exponential backoff (10s - 600s) |
| Max Delivery Attempts | 5 (configurable) |
| Message Retention | 7 days |
| Exactly Once Delivery | Optional |

### 3. Dead Letter Queue (DLQ)

**Purpose**: Captures messages that fail processing after max delivery attempts.

| Component | Description |
|-----------|-------------|
| DLQ Topic | Receives failed messages |
| DLQ Subscription | Pull-based for manual inspection |
| Retention | 7 days |

### 4. Cloud Run Service

**Purpose**: Processes events received from Pub/Sub.

| Property | Configuration |
|----------|---------------|
| Scaling | 0-100 instances (configurable) |
| Concurrency | 80 requests/instance |
| CPU | 1 vCPU |
| Memory | 512Mi |
| Timeout | 300 seconds |
| Health Check | /health endpoint |

### 5. Service Accounts

| Service Account | Purpose | Key Permissions |
|-----------------|---------|-----------------|
| Cloud Run SA | Run event processor | `cloudtrace.agent`, `errorreporting.writer`, `monitoring.metricWriter` |
| Pub/Sub SA | Invoke Cloud Run | `run.invoker` |

## Message Flow

### Normal Flow

```
1. Producer publishes message to Pub/Sub Topic
2. Pub/Sub delivers message to Push Subscription
3. Push Subscription sends HTTP POST to Cloud Run with OIDC token
4. Cloud Run processes message and returns 2xx response
5. Pub/Sub marks message as acknowledged
```

### Failure Flow

```
1. Cloud Run returns non-2xx response or times out
2. Pub/Sub retries with exponential backoff
3. After max_delivery_attempts failures:
   - Message is published to Dead Letter Topic
   - DLQ Subscription receives message for inspection
   - Alert is triggered via Cloud Monitoring
```

## Message Format

### Pub/Sub Message Structure

```json
{
  "message": {
    "data": "<base64-encoded-payload>",
    "attributes": {
      "published_at": "2024-01-15T10:30:00Z",
      "publisher": "test-publisher"
    },
    "messageId": "1234567890",
    "publishTime": "2024-01-15T10:30:00.000Z"
  },
  "subscription": "projects/PROJECT_ID/subscriptions/SUBSCRIPTION_NAME"
}
```

### Recommended Payload Format

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "order_created",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "data": {
    "order_id": "12345",
    "customer_id": "cust-001",
    "amount": 99.99
  }
}
```

## Observability

### Dashboard Metrics

| Metric | Description | Source |
|--------|-------------|--------|
| Message Publish Rate | Messages published per second | `pubsub.googleapis.com/topic/send_request_count` |
| Undelivered Messages | Messages pending delivery | `pubsub.googleapis.com/subscription/num_undelivered_messages` |
| Request Rate | Cloud Run requests per second | `run.googleapis.com/request_count` |
| Error Rate | 4xx/5xx responses per second | `run.googleapis.com/request_count` by response_code_class |
| Latency | p50/p95/p99 request latency | `run.googleapis.com/request_latencies` |
| Instance Count | Active Cloud Run instances | `run.googleapis.com/container/instance_count` |
| CPU Utilization | Container CPU usage | `run.googleapis.com/container/cpu/utilizations` |
| Memory Utilization | Container memory usage | `run.googleapis.com/container/memory/utilizations` |
| DLQ Message Count | Failed messages in DLQ | `pubsub.googleapis.com/subscription/num_undelivered_messages` |

### Alert Policies

| Alert | Condition | Threshold |
|-------|-----------|-----------|
| Dead Letter Queue Alert | DLQ has undelivered messages | > 0 (configurable) |
| High Error Rate | 5xx errors per second | > 5/s (configurable) |
| Old Unacked Messages | Message age in subscription | > 300s (configurable) |
| Error Reporting Alert | Error log entries per second | > 1/s (configurable) |

### Logging

Cloud Run logs are automatically collected in Cloud Logging with:
- Structured JSON logging support
- Severity levels (DEBUG, INFO, WARNING, ERROR)
- Request tracing integration

### Distributed Tracing

Cloud Trace integration is enabled via environment variables:
- `GOOGLE_CLOUD_TRACE_ENABLED=true`
- `GOOGLE_CLOUD_TRACE_SAMPLING_RATE=0.1`

Application must use OpenTelemetry or Cloud Trace SDK for instrumentation.

## Security

### Authentication

| Component | Authentication Method |
|-----------|----------------------|
| Pub/Sub → Cloud Run | OIDC Token (Service Account) |
| Cloud Run (Public) | No external access (Pub/Sub only via IAM) |

### IAM Bindings

```
Pub/Sub Service Account
  └─▶ roles/run.invoker (Cloud Run Service)

Google-managed Pub/Sub SA (service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com)
  ├─▶ roles/run.invoker (Cloud Run Service)
  ├─▶ roles/pubsub.publisher (Dead Letter Topic)
  └─▶ roles/pubsub.subscriber (Event Subscription)

Cloud Run Service Account
  ├─▶ roles/cloudtrace.agent (Project) [if trace enabled]
  ├─▶ roles/errorreporting.writer (Project) [if error reporting enabled]
  └─▶ roles/monitoring.metricWriter (Project) [if custom metrics enabled]
```

### Secrets Management

Sensitive configuration is managed via:
- `secrets.auto.tfvars` (local development, git-ignored)
- GCP Secret Manager (production, accessed by GitHub Actions)

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment | - |
| `PROJECT_ID` | GCP project ID | - |
| `LOG_LEVEL` | Logging verbosity | INFO |
| `GOOGLE_CLOUD_TRACE_ENABLED` | Enable tracing | false |
| `GOOGLE_CLOUD_TRACE_SAMPLING_RATE` | Trace sampling rate | 0.1 |
| `GOOGLE_CLOUD_ERROR_REPORTING_ENABLED` | Enable error reporting | false |

### Terraform Variables

See `variables.tf` for complete list. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | dev/staging/prod | - |
| `project_id` | GCP project ID | - |
| `region` | GCP region | asia-northeast1 |
| `min_instances` | Minimum Cloud Run instances | 0 |
| `max_instances` | Maximum Cloud Run instances | 100 |
| `max_delivery_attempts` | Retries before DLQ | 5 |
| `enable_monitoring` | Enable alert policies | true |

## Module Structure

```
architectures/event-driven/gcp/
├── main.tf                 # Module orchestration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── versions.tf             # Version constraints (>= 1.13)
├── backend.tf              # Remote state configuration
├── dev.auto.tfvars         # Dev environment settings
├── secrets.auto.tfvars     # Sensitive values (git-ignored)
├── modules/
│   ├── service_accounts/   # SA creation
│   ├── cloudrun/           # Cloud Run service
│   ├── pubsub/             # Topics and subscriptions
│   ├── iam_bindings/       # IAM configuration
│   ├── monitoring/         # Alert policies
│   └── observability/      # Dashboard, logging, tracing
├── tests/                  # Terraform native tests
│   ├── variables_validation.tftest.hcl
│   └── conditional_resources.tftest.hcl
└── examples/
    ├── publisher.py        # Test publisher script
    ├── requirements.txt
    └── README.md
```

## Deployment Order

Terraform modules are deployed in dependency order:

```
1. service_accounts    # No dependencies
       ↓
2. cloudrun           # Depends on: service_accounts
       ↓
3. pubsub             # Depends on: cloudrun (for push endpoint)
       ↓
4. iam_bindings       # Depends on: service_accounts, cloudrun, pubsub
       ↓
5. monitoring         # Depends on: cloudrun, pubsub
       ↓
6. observability      # Depends on: cloudrun, pubsub
```

## Testing

### Publisher Script

Test message publishing using the provided Python script:

```bash
cd architectures/event-driven/gcp/examples
pip install -r requirements.txt
python publisher.py -p PROJECT_ID -t TOPIC_NAME --count 10
```

### Terraform Tests

```bash
cd architectures/event-driven/gcp
terraform test -test-directory=tests
```

Tests cover:
- Variable validation (56 test cases)
- Conditional resource creation
- Module integration

## Limitations and Considerations

### Ack Deadline vs Request Timeout

- Default `ack_deadline_seconds`: 60s
- Default `request_timeout`: 300s

If processing takes longer than `ack_deadline_seconds`, messages may be redelivered. Adjust `ack_deadline_seconds` to match or exceed `request_timeout`.

### DLQ Processing

DLQ Subscription is Pull-based. Failed messages require manual inspection or additional automation (e.g., Cloud Functions) for processing.

### Exactly Once Delivery

Disabled by default. When enabled:
- Higher latency
- Requires idempotent message processing
- Not compatible with all use cases

## References

- [Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
