# Cloud Run Module Tests
# Tests Cloud Run service configuration, naming, and conditional logic

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
# Cloud Run Service Naming Tests
# =============================================================================

run "cloudrun_service_naming" {
  command = plan

  assert {
    condition     = output.cloud_run_service_name == "dev-events-event-processor"
    error_message = "Cloud Run service name should be 'dev-events-event-processor'"
  }

  assert {
    condition     = output.cloud_run_location == "asia-northeast1"
    error_message = "Cloud Run location should match region variable"
  }
}

run "cloudrun_service_naming_prod" {
  command = plan

  variables {
    environment  = "prod"
    project_name = "orders"
    region       = "us-central1"
  }

  assert {
    condition     = output.cloud_run_service_name == "prod-orders-event-processor"
    error_message = "Cloud Run service name should reflect environment and project_name"
  }

  assert {
    condition     = output.cloud_run_location == "us-central1"
    error_message = "Cloud Run location should match region variable"
  }
}

# =============================================================================
# Health Check Configuration Tests
# =============================================================================

run "cloudrun_health_check_enabled" {
  command = plan

  variables {
    enable_health_check = true
    health_check_path   = "/health"
  }

  # Health check configuration is applied when enabled
}

run "cloudrun_health_check_disabled" {
  command = plan

  variables {
    enable_health_check = false
  }

  # Health check configuration should not be applied when disabled
}

run "cloudrun_custom_health_check_path" {
  command = plan

  variables {
    enable_health_check = true
    health_check_path   = "/api/health"
  }

  # Custom health check path should be used
}

# =============================================================================
# VPC Configuration Tests
# =============================================================================

run "cloudrun_without_vpc_connector" {
  command = plan

  variables {
    vpc_connector_name = ""
  }

  # VPC configuration should not be applied when connector is empty
}

run "cloudrun_with_vpc_connector" {
  command = plan

  variables {
    vpc_connector_name = "my-vpc-connector"
    vpc_egress         = "ALL_TRAFFIC"
  }

  # VPC configuration should be applied when connector is specified
}

# =============================================================================
# Scaling Configuration Tests
# =============================================================================

run "cloudrun_scaling_config" {
  command = plan

  variables {
    min_instances = 1
    max_instances = 10
    concurrency   = 80
  }

  # Scaling configuration should be applied
}

run "cloudrun_scale_to_zero" {
  command = plan

  variables {
    min_instances = 0
    max_instances = 100
  }

  # Scale to zero should be allowed
}

# =============================================================================
# Resource Limits Tests
# =============================================================================

run "cloudrun_resource_limits" {
  command = plan

  variables {
    cpu_limit    = "2"
    memory_limit = "1Gi"
  }

  # Resource limits should be applied
}

# =============================================================================
# Cloud Trace Configuration Tests
# =============================================================================

run "cloudrun_trace_enabled" {
  command = plan

  variables {
    enable_cloud_trace  = true
    trace_sampling_rate = 0.5
  }

  # Cloud Trace environment variables should be set
}

run "cloudrun_trace_disabled" {
  command = plan

  variables {
    enable_cloud_trace = false
  }

  # Cloud Trace environment variables should not be set
}
