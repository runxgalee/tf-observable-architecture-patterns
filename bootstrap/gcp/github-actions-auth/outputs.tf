output "workload_identity_provider" {
  description = "The full name of the Workload Identity Provider (set this as WIF_PROVIDER secret in GitHub)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Email of the service account (set this as WIF_SERVICE_ACCOUNT secret in GitHub)"
  value       = google_service_account.github_actions_terraform.email
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}

output "setup_instructions" {
  description = "Instructions for setting up GitHub secrets"
  value       = <<-EOT

    ========================================
    GitHub Secrets Setup Instructions
    ========================================

    Add the following secrets to your GitHub repository:

    Repository → Settings → Secrets and variables → Actions → New repository secret

    1. WIF_PROVIDER
       Value: ${google_iam_workload_identity_pool_provider.github.name}

    2. WIF_SERVICE_ACCOUNT
       Value: ${google_service_account.github_actions_terraform.email}

    ========================================
  EOT
}
