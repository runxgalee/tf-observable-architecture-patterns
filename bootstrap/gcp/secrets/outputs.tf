output "secret_ids" {
  description = "Map of all created secrets (key = secret_id)"
  value = {
    for secret_id, secret in google_secret_manager_secret.secrets :
    secret_id => secret.secret_id
  }
}

output "secret_full_names" {
  description = "Map of all secrets with their full resource names (for use in GitHub Actions)"
  value = {
    for secret_id, secret in google_secret_manager_secret.secrets :
    secret_id => "projects/${var.project_id}/secrets/${secret.secret_id}"
  }
}

output "secrets_by_environment" {
  description = "Secrets grouped by environment for easy reference"
  value = {
    for env in distinct([for s in var.secrets : s.environment]) :
    env => {
      for secret_id, secret in var.secrets :
      secret_id => {
        secret_id        = google_secret_manager_secret.secrets[secret_id].secret_id
        environment      = secret.environment
        full_name        = "projects/${var.project_id}/secrets/${google_secret_manager_secret.secrets[secret_id].secret_id}"
        service_accounts = secret.service_accounts
      }
      if secret.environment == env
    }
  }
}
