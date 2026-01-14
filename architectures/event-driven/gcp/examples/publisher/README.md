# Event-Driven Architecture Examples

This directory contains example scripts for testing the event-driven architecture deployment.

## Publisher Script

The `publisher.py` script allows you to publish test messages to Pub/Sub topics.

### Prerequisites

1. Python 3.10+
2. Google Cloud SDK authenticated (`gcloud auth application-default login`)
3. Appropriate IAM permissions (`roles/pubsub.publisher`)

### Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# or: venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
```

### Usage

#### Basic Usage

```bash
# Publish a single test message
python publisher.py --project-id YOUR_PROJECT_ID --topic YOUR_TOPIC_NAME

# Using environment variables
export GOOGLE_CLOUD_PROJECT=your-project-id
export PUBSUB_TOPIC=dev-events-events
python publisher.py
```

#### Publish Custom Message

```bash
python publisher.py -p my-project -t my-topic \
  --message '{"event_type": "order_created", "data": {"order_id": "12345", "amount": 99.99}}'
```

#### Publish Multiple Messages

```bash
# Publish 10 messages with 0.5s delay
python publisher.py -p my-project -t my-topic --count 10 --delay 0.5

# Publish 100 messages rapidly
python publisher.py -p my-project -t my-topic --count 100 --delay 0
```

#### Publish from File

Create a `messages.json` file:

```json
[
  {"event_type": "user_created", "data": {"user_id": "u001", "email": "user1@example.com"}},
  {"event_type": "user_created", "data": {"user_id": "u002", "email": "user2@example.com"}},
  {"event_type": "order_created", "data": {"order_id": "o001", "amount": 150.00}}
]
```

Then publish:

```bash
python publisher.py -p my-project -t my-topic --file messages.json
```

#### Test Error Handling (DLQ)

To test the Dead Letter Queue functionality, publish messages with `event_type: error`:

```bash
python publisher.py -p my-project -t my-topic --event-type error --count 5
```

> Note: Your Cloud Run handler must be configured to reject messages with `event_type: error` for DLQ testing.

### Command Reference

| Option | Short | Description |
|--------|-------|-------------|
| `--project-id` | `-p` | GCP Project ID |
| `--topic` | `-t` | Pub/Sub topic name |
| `--message` | `-m` | JSON message to publish |
| `--count` | `-c` | Number of messages to publish (default: 1) |
| `--delay` | `-d` | Delay between messages in seconds (default: 0.1) |
| `--file` | `-f` | JSON file containing messages |
| `--event-type` | `-e` | Event type for generated messages (default: test) |
| `--verbose` | `-v` | Enable verbose logging |

### Getting Topic Name from Terraform

After deploying the infrastructure, get the topic name:

```bash
cd ../
terraform output topic_name
```

Or use the generated command:

```bash
terraform output publish_test_message_command
```

### Example Message Format

Messages published by the script follow this format:

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "test",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "data": {
    "message": "Hello from publisher!",
    "source": "test-publisher",
    "sequence": 1,
    "total": 10
  }
}
```

### Troubleshooting

#### Permission Denied

Ensure your account has the `roles/pubsub.publisher` role:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/pubsub.publisher"
```

#### Topic Not Found

Verify the topic exists:

```bash
gcloud pubsub topics list --project=YOUR_PROJECT_ID
```
