# Conditional Resources Tests
# Tests for resources with count/dynamic blocks (conditional creation)

# -----------------------------------------------------------------------------
# Common Test Configuration
# -----------------------------------------------------------------------------
mock_provider "google" {
  override_data {
    target = module.iam_bindings.data.google_project.project
    values = {
      project_id = "test-project"
      number     = "123456789012"
    }
  }
}

variables {
  project_id      = "test-project"
  region          = "asia-northeast1"
  environment     = "dev"
  project_name    = "events"
  container_image = "gcr.io/test/image:latest"
}
# -----------------------------------------------------------------------------

# =============================================================================
# Monitoring Module: enable_monitoring (count)
# Controls: 3 alert policies
# =============================================================================

run "monitoring_enabled" {
  command = plan

  variables {
    enable_monitoring = true
  }

  assert {
    condition     = length(output.alert_policy_ids) == 3
    error_message = "Expected 3 alert policies when monitoring is enabled"
  }
}

run "monitoring_disabled" {
  command = plan

  variables {
    enable_monitoring = false
  }

  assert {
    condition     = length(output.alert_policy_ids) == 0
    error_message = "Expected 0 alert policies when monitoring is disabled"
  }
}

# =============================================================================
# Observability Module: enable_observability_dashboard (count)
# Controls: Cloud Monitoring dashboard
# =============================================================================

run "observability_dashboard_enabled" {
  command = plan

  variables {
    enable_observability_dashboard = true
  }

  # Note: monitoring_dashboard_url contains resource ID which is unknown at plan time
  # We verify the feature is enabled via observability_enabled instead
  assert {
    condition     = output.observability_enabled.dashboard == true
    error_message = "observability_enabled.dashboard should be true"
  }
}

run "observability_dashboard_disabled" {
  command = plan

  variables {
    enable_observability_dashboard = false
  }

  assert {
    condition     = output.observability_enabled.dashboard == false
    error_message = "observability_enabled.dashboard should be false"
  }
}

# =============================================================================
# Observability Module: enable_cloud_trace (count via iam_bindings)
# Controls: Cloud Trace IAM binding, Cloud Trace URL output
# =============================================================================

run "cloud_trace_enabled" {
  command = plan

  variables {
    enable_cloud_trace = true
  }

  # Note: cloud_trace_url is a static URL based on var, but we test via observability_enabled
  # for consistency with other conditional resource tests
  assert {
    condition     = output.observability_enabled.cloud_trace == true
    error_message = "observability_enabled.cloud_trace should be true"
  }
}

run "cloud_trace_disabled" {
  command = plan

  variables {
    enable_cloud_trace = false
  }

  assert {
    condition     = output.observability_enabled.cloud_trace == false
    error_message = "observability_enabled.cloud_trace should be false"
  }
}

# =============================================================================
# Observability Module: enable_error_reporting_metric (count)
# Controls: Error reporting log-based metric
# =============================================================================

run "error_reporting_metric_enabled" {
  command = plan

  variables {
    enable_error_reporting_metric = true
  }

  assert {
    condition     = output.observability_enabled.error_reporting == true
    error_message = "observability_enabled.error_reporting should be true"
  }
}

run "error_reporting_metric_disabled" {
  command = plan

  variables {
    enable_error_reporting_metric = false
  }

  assert {
    condition     = output.observability_enabled.error_reporting == false
    error_message = "observability_enabled.error_reporting should be false"
  }
}

# =============================================================================
# Observability Module: enable_error_log_sink (count)
# Controls: Log sink to BigQuery
# =============================================================================

run "error_log_sink_enabled" {
  command = plan

  variables {
    enable_error_log_sink = true
    error_log_dataset_id  = "test_dataset"
  }

  assert {
    condition     = output.observability_enabled.log_sink == true
    error_message = "observability_enabled.log_sink should be true"
  }
}

run "error_log_sink_disabled" {
  command = plan

  variables {
    enable_error_log_sink = false
  }

  assert {
    condition     = output.observability_enabled.log_sink == false
    error_message = "observability_enabled.log_sink should be false"
  }
}

# =============================================================================
# Combined Observability Features
# =============================================================================

run "all_observability_enabled" {
  command = plan

  variables {
    enable_monitoring              = true
    enable_observability_dashboard = true
    enable_cloud_trace             = true
    enable_error_reporting_metric  = true
    enable_error_log_sink          = true
    error_log_dataset_id           = "test_dataset"
  }

  assert {
    condition     = length(output.alert_policy_ids) == 3
    error_message = "Expected 3 alert policies"
  }

  assert {
    condition     = output.observability_enabled.dashboard == true
    error_message = "Dashboard should be enabled"
  }

  assert {
    condition     = output.observability_enabled.cloud_trace == true
    error_message = "Cloud Trace should be enabled"
  }

  assert {
    condition     = output.observability_enabled.error_reporting == true
    error_message = "Error Reporting should be enabled"
  }

  assert {
    condition     = output.observability_enabled.log_sink == true
    error_message = "Log Sink should be enabled"
  }
}

run "all_observability_disabled" {
  command = plan

  variables {
    enable_monitoring              = false
    enable_observability_dashboard = false
    enable_cloud_trace             = false
    enable_error_reporting_metric  = false
    enable_error_log_sink          = false
  }

  assert {
    condition     = length(output.alert_policy_ids) == 0
    error_message = "Expected 0 alert policies"
  }

  assert {
    condition     = output.observability_enabled.dashboard == false
    error_message = "Dashboard should be disabled"
  }

  assert {
    condition     = output.observability_enabled.cloud_trace == false
    error_message = "Cloud Trace should be disabled"
  }

  assert {
    condition     = output.observability_enabled.error_reporting == false
    error_message = "Error Reporting should be disabled"
  }

  assert {
    condition     = output.observability_enabled.log_sink == false
    error_message = "Log Sink should be disabled"
  }
}
