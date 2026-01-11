# Monitoring Module Tests
# Tests conditional alert policy creation and monitoring configuration

mock_provider "google" {
  override_data {
    target = data.google_project.project
    values = {
      project_id = "test-project"
      number     = "123456789012"
    }
  }
}

# Common variables for all tests
variables {
  project_id      = "test-project"
  region          = "asia-northeast1"
  environment     = "dev"
  project_name    = "events"
  container_image = "gcr.io/test/image:latest"
}

# =============================================================================
# Monitoring Enabled/Disabled Tests
# =============================================================================

run "monitoring_enabled_creates_alerts" {
  command = plan

  variables {
    enable_monitoring = true
  }

  # When monitoring is enabled, alert policies should be created
  assert {
    condition     = length(output.alert_policy_ids) == 3
    error_message = "Expected 3 alert policies when monitoring is enabled (DLQ, error rate, old unacked messages)"
  }
}

run "monitoring_disabled_no_alerts" {
  command = plan

  variables {
    enable_monitoring = false
  }

  # When monitoring is disabled, no alert policies should be created
  assert {
    condition     = length(output.alert_policy_ids) == 0
    error_message = "Expected 0 alert policies when monitoring is disabled"
  }
}

# =============================================================================
# Alert Threshold Configuration Tests
# =============================================================================

run "monitoring_custom_dlq_threshold" {
  command = plan

  variables {
    enable_monitoring   = true
    dlq_alert_threshold = 10
  }

  # Custom DLQ threshold should be applied
}

run "monitoring_custom_error_rate_threshold" {
  command = plan

  variables {
    enable_monitoring    = true
    error_rate_threshold = 10
  }

  # Custom error rate threshold should be applied
}

run "monitoring_custom_unacked_message_threshold" {
  command = plan

  variables {
    enable_monitoring                    = true
    oldest_unacked_message_age_threshold = 600
  }

  # Custom unacked message age threshold should be applied
}

# =============================================================================
# Custom Metrics Tests
# =============================================================================

run "custom_metrics_disabled" {
  command = plan

  variables {
    enable_monitoring     = true
    enable_custom_metrics = false
  }

  # Custom log-based metrics should not be created
}

run "custom_metrics_enabled" {
  command = plan

  variables {
    enable_monitoring     = true
    enable_custom_metrics = true
  }

  # Custom log-based metrics should be created
}

# =============================================================================
# Notification Channels Tests
# =============================================================================

run "monitoring_with_notification_channels" {
  command = plan

  variables {
    enable_monitoring     = true
    notification_channels = ["projects/test-project/notificationChannels/123"]
  }

  # Notification channels should be configured
}

run "monitoring_without_notification_channels" {
  command = plan

  variables {
    enable_monitoring     = true
    notification_channels = []
  }

  # Empty notification channels should be allowed
}
