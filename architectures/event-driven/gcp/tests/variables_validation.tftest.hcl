# Variables Validation Tests
# Tests variable validation rules for all variables with validation blocks

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
  project_name    = "events"
  container_image = "gcr.io/test/image:latest"
}
# -----------------------------------------------------------------------------

# =============================================================================
# environment: must be one of dev, staging, prod
# =============================================================================

run "environment_valid_dev" {
  command = plan
  variables { environment = "dev" }
}

run "environment_valid_staging" {
  command = plan
  variables { environment = "staging" }
}

run "environment_valid_prod" {
  command = plan
  variables { environment = "prod" }
}

run "environment_invalid_test" {
  command = plan
  variables { environment = "test" }
  expect_failures = [var.environment]
}

run "environment_invalid_production" {
  command = plan
  variables { environment = "production" }
  expect_failures = [var.environment]
}

# =============================================================================
# ack_deadline_seconds: 10-600
# =============================================================================

run "ack_deadline_valid_min" {
  command = plan
  variables {
    environment          = "dev"
    ack_deadline_seconds = 10
  }
}

run "ack_deadline_valid_max" {
  command = plan
  variables {
    environment          = "dev"
    ack_deadline_seconds = 600
  }
}

run "ack_deadline_invalid_below_min" {
  command = plan
  variables {
    environment          = "dev"
    ack_deadline_seconds = 9
  }
  expect_failures = [var.ack_deadline_seconds]
}

run "ack_deadline_invalid_above_max" {
  command = plan
  variables {
    environment          = "dev"
    ack_deadline_seconds = 601
  }
  expect_failures = [var.ack_deadline_seconds]
}

# =============================================================================
# max_delivery_attempts: 5-100
# =============================================================================

run "max_delivery_attempts_valid_min" {
  command = plan
  variables {
    environment           = "dev"
    max_delivery_attempts = 5
  }
}

run "max_delivery_attempts_valid_max" {
  command = plan
  variables {
    environment           = "dev"
    max_delivery_attempts = 100
  }
}

run "max_delivery_attempts_invalid_below_min" {
  command = plan
  variables {
    environment           = "dev"
    max_delivery_attempts = 4
  }
  expect_failures = [var.max_delivery_attempts]
}

run "max_delivery_attempts_invalid_above_max" {
  command = plan
  variables {
    environment           = "dev"
    max_delivery_attempts = 101
  }
  expect_failures = [var.max_delivery_attempts]
}

# =============================================================================
# min_instances: 0-1000
# =============================================================================

run "min_instances_valid_zero" {
  command = plan
  variables {
    environment   = "dev"
    min_instances = 0
  }
}

run "min_instances_valid_max" {
  command = plan
  variables {
    environment   = "dev"
    min_instances = 1000
  }
}

run "min_instances_invalid_negative" {
  command = plan
  variables {
    environment   = "dev"
    min_instances = -1
  }
  expect_failures = [var.min_instances]
}

run "min_instances_invalid_above_max" {
  command = plan
  variables {
    environment   = "dev"
    min_instances = 1001
  }
  expect_failures = [var.min_instances]
}

# =============================================================================
# max_instances: 1-1000
# =============================================================================

run "max_instances_valid_min" {
  command = plan
  variables {
    environment   = "dev"
    max_instances = 1
  }
}

run "max_instances_valid_max" {
  command = plan
  variables {
    environment   = "dev"
    max_instances = 1000
  }
}

run "max_instances_invalid_zero" {
  command = plan
  variables {
    environment   = "dev"
    max_instances = 0
  }
  expect_failures = [var.max_instances]
}

run "max_instances_invalid_above_max" {
  command = plan
  variables {
    environment   = "dev"
    max_instances = 1001
  }
  expect_failures = [var.max_instances]
}

# =============================================================================
# concurrency: 1-1000
# =============================================================================

run "concurrency_valid_min" {
  command = plan
  variables {
    environment = "dev"
    concurrency = 1
  }
}

run "concurrency_valid_max" {
  command = plan
  variables {
    environment = "dev"
    concurrency = 1000
  }
}

run "concurrency_invalid_zero" {
  command = plan
  variables {
    environment = "dev"
    concurrency = 0
  }
  expect_failures = [var.concurrency]
}

run "concurrency_invalid_above_max" {
  command = plan
  variables {
    environment = "dev"
    concurrency = 1001
  }
  expect_failures = [var.concurrency]
}

# =============================================================================
# request_timeout: 1-3600
# =============================================================================

run "request_timeout_valid_min" {
  command = plan
  variables {
    environment     = "dev"
    request_timeout = 1
  }
}

run "request_timeout_valid_max" {
  command = plan
  variables {
    environment     = "dev"
    request_timeout = 3600
  }
}

run "request_timeout_invalid_zero" {
  command = plan
  variables {
    environment     = "dev"
    request_timeout = 0
  }
  expect_failures = [var.request_timeout]
}

run "request_timeout_invalid_above_max" {
  command = plan
  variables {
    environment     = "dev"
    request_timeout = 3601
  }
  expect_failures = [var.request_timeout]
}

# =============================================================================
# log_level: DEBUG, INFO, WARNING, ERROR
# =============================================================================

run "log_level_valid_debug" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "DEBUG"
  }
}

run "log_level_valid_info" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "INFO"
  }
}

run "log_level_valid_warning" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "WARNING"
  }
}

run "log_level_valid_error" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "ERROR"
  }
}

run "log_level_invalid_lowercase" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "info"
  }
  expect_failures = [var.log_level]
}

run "log_level_invalid_trace" {
  command = plan
  variables {
    environment = "dev"
    log_level   = "TRACE"
  }
  expect_failures = [var.log_level]
}

# =============================================================================
# vpc_egress: ALL_TRAFFIC, PRIVATE_RANGES_ONLY
# =============================================================================

run "vpc_egress_valid_all_traffic" {
  command = plan
  variables {
    environment = "dev"
    vpc_egress  = "ALL_TRAFFIC"
  }
}

run "vpc_egress_valid_private_ranges" {
  command = plan
  variables {
    environment = "dev"
    vpc_egress  = "PRIVATE_RANGES_ONLY"
  }
}

run "vpc_egress_invalid_lowercase" {
  command = plan
  variables {
    environment = "dev"
    vpc_egress  = "all_traffic"
  }
  expect_failures = [var.vpc_egress]
}

run "vpc_egress_invalid_value" {
  command = plan
  variables {
    environment = "dev"
    vpc_egress  = "INVALID"
  }
  expect_failures = [var.vpc_egress]
}

# =============================================================================
# trace_sampling_rate: 0.0-1.0
# =============================================================================

run "trace_sampling_rate_valid_zero" {
  command = plan
  variables {
    environment         = "dev"
    trace_sampling_rate = 0
  }
}

run "trace_sampling_rate_valid_half" {
  command = plan
  variables {
    environment         = "dev"
    trace_sampling_rate = 0.5
  }
}

run "trace_sampling_rate_valid_one" {
  command = plan
  variables {
    environment         = "dev"
    trace_sampling_rate = 1
  }
}

run "trace_sampling_rate_invalid_negative" {
  command = plan
  variables {
    environment         = "dev"
    trace_sampling_rate = -0.1
  }
  expect_failures = [var.trace_sampling_rate]
}

run "trace_sampling_rate_invalid_above_one" {
  command = plan
  variables {
    environment         = "dev"
    trace_sampling_rate = 1.1
  }
  expect_failures = [var.trace_sampling_rate]
}
