# Pub/Sub Topic for events
resource "google_pubsub_topic" "event_topic" {
  name    = "${local.resource_prefix}-${var.topic_name}"
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  labels = merge(
    local.common_labels,
    {
      type = "event-topic"
    }
  )
}

# Dead Letter Topic for failed messages
resource "google_pubsub_topic" "dead_letter_topic" {
  name    = "${local.resource_prefix}-${var.topic_name}-dead-letter"
  project = var.project_id

  labels = merge(
    local.common_labels,
    {
      type = "dead-letter-topic"
    }
  )
}

# Push Subscription to Cloud Run
resource "google_pubsub_subscription" "event_subscription" {
  name    = "${local.resource_prefix}-${var.topic_name}-subscription"
  topic   = google_pubsub_topic.event_topic.name
  project = var.project_id

  push_config {
    push_endpoint = var.push_endpoint

    oidc_token {
      service_account_email = var.oidc_service_account_email
    }

    attributes = {
      x-goog-version = "v1"
    }
  }

  # Acknowledgement deadline
  ack_deadline_seconds = var.ack_deadline_seconds

  # Retry policy with exponential backoff
  retry_policy {
    minimum_backoff = var.retry_minimum_backoff
    maximum_backoff = var.retry_maximum_backoff
  }

  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter_topic.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Message retention
  message_retention_duration = var.subscription_message_retention_duration

  # Enable exactly once delivery if specified
  enable_exactly_once_delivery = var.enable_exactly_once_delivery

  labels = merge(
    local.common_labels,
    {
      type = "event-subscription"
    }
  )
}

# Dead Letter Subscription for monitoring
resource "google_pubsub_subscription" "dead_letter_subscription" {
  name    = "${local.resource_prefix}-${var.topic_name}-dead-letter-subscription"
  topic   = google_pubsub_topic.dead_letter_topic.name
  project = var.project_id

  message_retention_duration = "604800s" # 7 days

  labels = merge(
    local.common_labels,
    {
      type = "dead-letter-subscription"
    }
  )
}
