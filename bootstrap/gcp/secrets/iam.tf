# Grant service accounts access to Secret Manager secrets
# Each secret can specify which service accounts need access

locals {
  # Flatten secrets and service accounts to create IAM bindings
  # Input: var.secrets with service_accounts list
  # Output: Map with composite key for each secret-service account pair
  # Example: "dev-wif-service-account--github-actions@project.iam.gserviceaccount.com" = { ... }
  iam_bindings_map = merge([
    for secret_id, secret in var.secrets : {
      for sa in secret.service_accounts :
      "${secret_id}--${sa}" => {
        secret_id       = secret_id
        service_account = sa
      }
    }
  ]...)
}

# Grant Secret Accessor role to service accounts
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each  = local.iam_bindings_map
  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.service_account}"
}
