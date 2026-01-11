# Variables Validation Tests
# Tests that variable validation rules work correctly

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
  container_image = "gcr.io/test/image:latest"
}

# =============================================================================
# Environment Variable Tests
# =============================================================================

run "valid_environment_dev" {
  command = plan

  variables {
    environment = "dev"
  }
}

run "valid_environment_staging" {
  command = plan

  variables {
    environment = "staging"
  }
}

run "valid_environment_prod" {
  command = plan

  variables {
    environment = "prod"
  }
}

run "invalid_environment_test" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "invalid_environment_production" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

# =============================================================================
# ack_deadline_seconds Tests (10-600)
# =============================================================================

run "valid_ack_deadline_minimum" {
  command = plan

  variables {
    environment          = "dev"
    ack_deadline_seconds = 10
  }
}

run "valid_ack_deadline_maximum" {
  command = plan

  variables {
    environment          = "dev"
    ack_deadline_seconds = 600
  }
}

run "invalid_ack_deadline_below_minimum" {
  command = plan

  variables {
    environment          = "dev"
    ack_deadline_seconds = 9
  }

  expect_failures = [var.ack_deadline_seconds]
}

run "invalid_ack_deadline_above_maximum" {
  command = plan

  variables {
    environment          = "dev"
    ack_deadline_seconds = 601
  }

  expect_failures = [var.ack_deadline_seconds]
}

# =============================================================================
# max_delivery_attempts Tests (5-100)
# =============================================================================

run "valid_max_delivery_attempts_minimum" {
  command = plan

  variables {
    environment           = "dev"
    max_delivery_attempts = 5
  }
}

run "valid_max_delivery_attempts_maximum" {
  command = plan

  variables {
    environment           = "dev"
    max_delivery_attempts = 100
  }
}

run "invalid_max_delivery_attempts_below_minimum" {
  command = plan

  variables {
    environment           = "dev"
    max_delivery_attempts = 4
  }

  expect_failures = [var.max_delivery_attempts]
}

run "invalid_max_delivery_attempts_above_maximum" {
  command = plan

  variables {
    environment           = "dev"
    max_delivery_attempts = 101
  }

  expect_failures = [var.max_delivery_attempts]
}

# =============================================================================
# min_instances Tests (0-1000)
# =============================================================================

run "valid_min_instances_zero" {
  command = plan

  variables {
    environment   = "dev"
    min_instances = 0
  }
}

run "valid_min_instances_maximum" {
  command = plan

  variables {
    environment   = "dev"
    min_instances = 1000
  }
}

run "invalid_min_instances_negative" {
  command = plan

  variables {
    environment   = "dev"
    min_instances = -1
  }

  expect_failures = [var.min_instances]
}

run "invalid_min_instances_above_maximum" {
  command = plan

  variables {
    environment   = "dev"
    min_instances = 1001
  }

  expect_failures = [var.min_instances]
}

# =============================================================================
# max_instances Tests (1-1000)
# =============================================================================

run "valid_max_instances_minimum" {
  command = plan

  variables {
    environment   = "dev"
    max_instances = 1
  }
}

run "valid_max_instances_maximum" {
  command = plan

  variables {
    environment   = "dev"
    max_instances = 1000
  }
}

run "invalid_max_instances_zero" {
  command = plan

  variables {
    environment   = "dev"
    max_instances = 0
  }

  expect_failures = [var.max_instances]
}

run "invalid_max_instances_above_maximum" {
  command = plan

  variables {
    environment   = "dev"
    max_instances = 1001
  }

  expect_failures = [var.max_instances]
}

# =============================================================================
# concurrency Tests (1-1000)
# =============================================================================

run "valid_concurrency_minimum" {
  command = plan

  variables {
    environment = "dev"
    concurrency = 1
  }
}

run "valid_concurrency_maximum" {
  command = plan

  variables {
    environment = "dev"
    concurrency = 1000
  }
}

run "invalid_concurrency_zero" {
  command = plan

  variables {
    environment = "dev"
    concurrency = 0
  }

  expect_failures = [var.concurrency]
}

run "invalid_concurrency_above_maximum" {
  command = plan

  variables {
    environment = "dev"
    concurrency = 1001
  }

  expect_failures = [var.concurrency]
}

# =============================================================================
# request_timeout Tests (1-3600)
# =============================================================================

run "valid_request_timeout_minimum" {
  command = plan

  variables {
    environment     = "dev"
    request_timeout = 1
  }
}

run "valid_request_timeout_maximum" {
  command = plan

  variables {
    environment     = "dev"
    request_timeout = 3600
  }
}

run "invalid_request_timeout_zero" {
  command = plan

  variables {
    environment     = "dev"
    request_timeout = 0
  }

  expect_failures = [var.request_timeout]
}

run "invalid_request_timeout_above_maximum" {
  command = plan

  variables {
    environment     = "dev"
    request_timeout = 3601
  }

  expect_failures = [var.request_timeout]
}

# =============================================================================
# log_level Tests (DEBUG, INFO, WARNING, ERROR)
# =============================================================================

run "valid_log_level_debug" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "DEBUG"
  }
}

run "valid_log_level_info" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "INFO"
  }
}

run "valid_log_level_warning" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "WARNING"
  }
}

run "valid_log_level_error" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "ERROR"
  }
}

run "invalid_log_level_lowercase" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "info"
  }

  expect_failures = [var.log_level]
}

run "invalid_log_level_trace" {
  command = plan

  variables {
    environment = "dev"
    log_level   = "TRACE"
  }

  expect_failures = [var.log_level]
}

# =============================================================================
# vpc_egress Tests (ALL_TRAFFIC, PRIVATE_RANGES_ONLY)
# =============================================================================

run "valid_vpc_egress_all_traffic" {
  command = plan

  variables {
    environment = "dev"
    vpc_egress  = "ALL_TRAFFIC"
  }
}

run "valid_vpc_egress_private_ranges" {
  command = plan

  variables {
    environment = "dev"
    vpc_egress  = "PRIVATE_RANGES_ONLY"
  }
}

run "invalid_vpc_egress_lowercase" {
  command = plan

  variables {
    environment = "dev"
    vpc_egress  = "all_traffic"
  }

  expect_failures = [var.vpc_egress]
}

# =============================================================================
# trace_sampling_rate Tests (0.0-1.0)
# =============================================================================

run "valid_trace_sampling_rate_zero" {
  command = plan

  variables {
    environment         = "dev"
    trace_sampling_rate = 0
  }
}

run "valid_trace_sampling_rate_half" {
  command = plan

  variables {
    environment         = "dev"
    trace_sampling_rate = 0.5
  }
}

run "valid_trace_sampling_rate_one" {
  command = plan

  variables {
    environment         = "dev"
    trace_sampling_rate = 1
  }
}

run "invalid_trace_sampling_rate_negative" {
  command = plan

  variables {
    environment         = "dev"
    trace_sampling_rate = -0.1
  }

  expect_failures = [var.trace_sampling_rate]
}

run "invalid_trace_sampling_rate_above_one" {
  command = plan

  variables {
    environment         = "dev"
    trace_sampling_rate = 1.1
  }

  expect_failures = [var.trace_sampling_rate]
}
