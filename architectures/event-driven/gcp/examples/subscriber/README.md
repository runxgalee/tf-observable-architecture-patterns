# Cloud Run Event Handler Example

A sample Node.js application for handling Pub/Sub push messages with structured logging for GCP Cloud Logging.

## Features

- Structured JSON logging compatible with Cloud Logging
- Trace context propagation for distributed tracing
- Pub/Sub push message parsing
- Health check endpoint
- Retryable vs non-retryable error handling

## Structured Logging

The application outputs logs in JSON format that Cloud Logging automatically parses:

```json
{
  "severity": "INFO",
  "message": "Message processed successfully",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "messageId": "123456789",
  "durationMs": 105,
  "logging.googleapis.com/trace": "projects/my-project/traces/abc123"
}
```

### Severity Levels

| Level | Usage |
|-------|-------|
| DEBUG | Detailed debugging information |
| INFO | General operational messages |
| WARNING | Unexpected but handled situations |
| ERROR | Errors requiring attention |

## Local Development

```bash
# Install dependencies
npm install

# Run locally
npm start

# Run with watch mode
npm run dev
```

## Testing Locally

```bash
# Health check
curl http://localhost:8080/health

# Simulate Pub/Sub push
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "messageId": "test-123",
      "publishTime": "2024-01-15T10:00:00.000Z",
      "data": "eyJldmVudCI6ICJ0ZXN0In0=",
      "attributes": {
        "eventType": "user.created"
      }
    },
    "subscription": "projects/my-project/subscriptions/my-sub"
  }'
```

## Build and Deploy

```bash
# Build container image
docker build -t cloudrun-event-handler .

# Run locally with Docker
docker run -p 8080:8080 -e PORT=8080 cloudrun-event-handler

# Deploy to Cloud Run (using gcloud)
gcloud run deploy event-handler \
  --source . \
  --region asia-northeast1 \
  --platform managed \
  --no-allow-unauthenticated
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 8080 |
| GOOGLE_CLOUD_PROJECT | GCP project ID (for trace context) | - |
| NODE_ENV | Environment name | development |

## Project Structure

```
example/
├── index.js          # Main application
├── package.json      # Dependencies
├── Dockerfile        # Container image
├── .dockerignore     # Docker build excludes
└── README.md         # This file
```
