# Secret Manager secrets for architectures and CI/CD
# These secrets provide centralized, secure storage for sensitive data
# used by GitHub Actions, architecture patterns, and monitoring systems

locals {
  common_labels = {
    managed_by = "terraform"
  }
}

# Create Secret Manager secrets
# Note: Secret data must be populated manually via gcloud or Console
resource "google_secret_manager_secret" "secrets" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key

  labels = merge(
    local.common_labels,
    var.additional_labels,
    {
      environment = each.value.environment
    }
  )

  annotations = {
    description = each.value.description
  }

  replication {
    auto {}
  }
}
