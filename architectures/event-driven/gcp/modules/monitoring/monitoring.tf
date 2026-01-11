# Monitoring: Alert policy for dead letter queue
resource "google_monitoring_alert_policy" "dead_letter_messages" {
  count = var.enable_monitoring ? 1 : 0

  display_name = "${var.environment} - ${var.project_name} - Dead Letter Queue Alert"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Dead Letter Queue has messages"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.dead_letter_subscription_name}\" AND metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.dlq_alert_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  documentation {
    content = <<-EOT
      Dead Letter Queue for ${var.environment} environment has accumulated messages.
      This indicates that events are failing to process after ${var.max_delivery_attempts} attempts.

      Investigation steps:
      1. Check Cloud Run logs for errors
      2. Review failed messages in the DLQ
      3. Verify downstream services are healthy
      4. Check for any recent code deployments
    EOT
  }

  enabled = true
}

# Alert policy for high error rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  count = var.enable_monitoring ? 1 : 0

  display_name = "${var.environment} - ${var.project_name} - High Error Rate"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Cloud Run 5xx error rate > ${var.error_rate_threshold}/s"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.cloud_run_service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content = <<-EOT
      Cloud Run service ${var.cloud_run_service_name} in ${var.environment}
      is experiencing a high 5xx server error rate (>${var.error_rate_threshold}/s).

      Investigation steps:
      1. Check Cloud Run logs for error details
      2. Review recent deployments
      3. Check resource limits (CPU, Memory)
      4. Verify external dependencies are healthy
    EOT
  }

  enabled = true
}

# Alert policy for old unacked messages
resource "google_monitoring_alert_policy" "old_unacked_messages" {
  count = var.enable_monitoring ? 1 : 0

  display_name = "${var.environment} - ${var.project_name} - Old Unacked Messages"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Oldest unacked message age > ${var.oldest_unacked_message_age_threshold}s"

    condition_threshold {
      filter          = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.event_subscription_name}\" AND metric.type = \"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.oldest_unacked_message_age_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content = <<-EOT
      Pub/Sub subscription ${var.event_subscription_name}
      has messages that have been unacknowledged for more than ${var.oldest_unacked_message_age_threshold} seconds.

      This may indicate:
      - Cloud Run service is down or unhealthy
      - Processing is taking too long
      - Subscription delivery issues

      Investigation steps:
      1. Check Cloud Run service health
      2. Review processing time metrics
      3. Check for any infrastructure issues
    EOT
  }

  enabled = true
}

# Log-based metric for custom monitoring (optional)
resource "google_logging_metric" "event_processing_success" {
  count = var.enable_custom_metrics ? 1 : 0

  name    = "${var.resource_prefix}_event_processing_success"
  project = var.project_id

  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${var.cloud_run_service_name}"
    jsonPayload.message="Event processed successfully"
  EOT

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "${var.environment} - Event Processing Success Count"
  }
}

resource "google_logging_metric" "event_processing_failure" {
  count = var.enable_custom_metrics ? 1 : 0

  name    = "${var.resource_prefix}_event_processing_failure"
  project = var.project_id

  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${var.cloud_run_service_name}"
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "${var.environment} - Event Processing Failure Count"
  }
}
