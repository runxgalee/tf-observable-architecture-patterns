# Cloud Run Service for event processing
resource "google_cloud_run_v2_service" "event_processor" {
  name     = "${local.resource_prefix}-event-processor"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }

        cpu_idle = var.cpu_always_allocated

        startup_cpu_boost = var.startup_cpu_boost
      }

      # Environment variables
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "LOG_LEVEL"
        value = var.log_level
      }

      # Cloud Trace configuration
      dynamic "env" {
        for_each = var.enable_cloud_trace ? [1] : []
        content {
          name  = "GOOGLE_CLOUD_TRACE_ENABLED"
          value = "true"
        }
      }

      dynamic "env" {
        for_each = var.enable_cloud_trace ? [1] : []
        content {
          name  = "GOOGLE_CLOUD_TRACE_SAMPLING_RATE"
          value = tostring(var.trace_sampling_rate)
        }
      }

      # Error Reporting configuration
      env {
        name  = "GOOGLE_CLOUD_ERROR_REPORTING_ENABLED"
        value = tostring(var.enable_error_reporting_metric)
      }

      # Additional environment variables from map
      dynamic "env" {
        for_each = var.additional_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.enable_health_check ? [1] : []
        content {
          http_get {
            path = var.health_check_path
          }
          initial_delay_seconds = 10
          timeout_seconds       = 3
          period_seconds        = 10
          failure_threshold     = 3
        }
      }

      # Startup probe
      dynamic "startup_probe" {
        for_each = var.enable_health_check ? [1] : []
        content {
          http_get {
            path = var.health_check_path
          }
          initial_delay_seconds = 0
          timeout_seconds       = 3
          period_seconds        = 10
          failure_threshold     = 3
        }
      }
    }

    # Maximum number of concurrent requests per instance
    max_instance_request_concurrency = var.concurrency

    # Timeout for requests
    timeout = "${var.request_timeout}s"

    # VPC Access Connector (if specified)
    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != "" ? [1] : []
      content {
        connector = var.vpc_connector_name
        egress    = var.vpc_egress
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = merge(
    local.common_labels,
    {
      type = "event-processor"
    }
  )
}
