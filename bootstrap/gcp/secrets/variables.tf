variable "project_id" {
  description = "GCP Project ID where Secret Manager secrets will be created"
  type        = string
}

variable "secrets" {
  description = <<-EOT
    Map of secrets to create in Secret Manager.
    Key: Secret identifier in format "{environment}-{name}" (e.g., "dev-wif-service-account")
    Value: Object with configuration for the secret

    Example:
    secrets = {
      "dev-wif-service-account" = {
        environment      = "dev"
        description      = "GitHub Actions WIF service account email"
        service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
      }
      "prod-wif-service-account" = {
        environment      = "prod"
        description      = "GitHub Actions WIF service account email"
        service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
      }
    }
  EOT
  type = map(object({
    environment      = string
    description      = string
    service_accounts = list(string)
  }))
}

variable "additional_labels" {
  description = "Additional labels to apply to all secrets"
  type        = map(string)
  default     = {}
}


