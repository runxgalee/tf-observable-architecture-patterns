# Outputs Tests
# Tests that outputs are properly structured and contain expected values

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
# Project Outputs Tests
# =============================================================================

run "project_outputs" {
  command = plan

  assert {
    condition     = output.project_id == "test-project"
    error_message = "project_id output should match input variable"
  }

  # Note: project_number comes from iam_bindings module's data source
  # which may not be overridden by the root mock_provider
}

# =============================================================================
# Configuration Summary Tests
# =============================================================================

run "configuration_summary_structure" {
  command = plan

  variables {
    min_instances     = 1
    max_instances     = 10
    concurrency       = 80
    cpu_limit         = "2"
    memory_limit      = "1Gi"
    enable_monitoring = true
  }

  assert {
    condition     = output.configuration_summary.environment == "dev"
    error_message = "configuration_summary should include environment"
  }

  assert {
    condition     = output.configuration_summary.project_name == "events"
    error_message = "configuration_summary should include project_name"
  }

  assert {
    condition     = output.configuration_summary.region == "asia-northeast1"
    error_message = "configuration_summary should include region"
  }

  assert {
    condition     = output.configuration_summary.min_instances == 1
    error_message = "configuration_summary should include min_instances"
  }

  assert {
    condition     = output.configuration_summary.max_instances == 10
    error_message = "configuration_summary should include max_instances"
  }

  assert {
    condition     = output.configuration_summary.concurrency == 80
    error_message = "configuration_summary should include concurrency"
  }

  assert {
    condition     = output.configuration_summary.monitoring_enabled == true
    error_message = "configuration_summary should include monitoring_enabled"
  }
}

# =============================================================================
# Observability URLs Tests
# =============================================================================

run "observability_urls_with_dashboard" {
  command = plan

  variables {
    enable_observability_dashboard = true
    enable_cloud_trace             = true
  }

  assert {
    condition     = output.monitoring_dashboard_url != null
    error_message = "monitoring_dashboard_url should be set when dashboard is enabled"
  }

  assert {
    condition     = output.cloud_trace_url != null
    error_message = "cloud_trace_url should be set when Cloud Trace is enabled"
  }

  assert {
    condition     = can(regex("console.cloud.google.com", output.error_reporting_url))
    error_message = "error_reporting_url should point to Cloud Console"
  }

  assert {
    condition     = can(regex("console.cloud.google.com/logs", output.cloud_logging_url))
    error_message = "cloud_logging_url should point to Cloud Logging"
  }
}

run "observability_urls_without_dashboard" {
  command = plan

  variables {
    enable_observability_dashboard = false
    enable_cloud_trace             = false
  }

  assert {
    condition     = output.monitoring_dashboard_url == null
    error_message = "monitoring_dashboard_url should be null when dashboard is disabled"
  }

  assert {
    condition     = output.cloud_trace_url == null
    error_message = "cloud_trace_url should be null when Cloud Trace is disabled"
  }
}

# =============================================================================
# Command Outputs Tests
# =============================================================================

run "command_outputs" {
  command = plan

  assert {
    condition     = can(regex("gcloud pubsub topics publish", output.publish_test_message_command))
    error_message = "publish_test_message_command should be a valid gcloud command"
  }

  assert {
    condition     = can(regex("gcloud logging read", output.view_logs_command))
    error_message = "view_logs_command should be a valid gcloud logging command"
  }
}

# =============================================================================
# Observability Enabled Map Tests
# =============================================================================

run "observability_enabled_all_features" {
  command = plan

  variables {
    enable_observability_dashboard = true
    enable_error_reporting_metric  = true
    enable_cloud_trace             = true
    enable_error_log_sink          = false
  }

  assert {
    condition     = output.observability_enabled.dashboard == true
    error_message = "observability_enabled.dashboard should be true"
  }

  assert {
    condition     = output.observability_enabled.error_reporting == true
    error_message = "observability_enabled.error_reporting should be true"
  }

  assert {
    condition     = output.observability_enabled.cloud_trace == true
    error_message = "observability_enabled.cloud_trace should be true"
  }

  assert {
    condition     = output.observability_enabled.log_sink == false
    error_message = "observability_enabled.log_sink should be false"
  }
}
