# Service Accounts Module Tests
# Tests service account configuration in different environments

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
# Service Account Configuration Tests
# =============================================================================

# Note: Service account email values are not known until apply time
# These tests verify that the configuration is valid and plans successfully

run "service_account_dev_environment" {
  command = plan

  # Plan should succeed with dev environment
}

run "service_account_prod_environment" {
  command = plan

  variables {
    environment  = "prod"
    project_name = "myapp"
  }

  # Plan should succeed with prod environment
}

run "service_account_staging_environment" {
  command = plan

  variables {
    environment  = "staging"
    project_name = "orders"
  }

  # Plan should succeed with staging environment
}
