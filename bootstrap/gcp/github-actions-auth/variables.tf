variable "project_id" {
  description = "GCP Project ID where the Workload Identity Pool will be created"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in the format 'owner/repo' (e.g., 'runxgalee/tf-observable-architecture-patterns')"
  type        = string
}

variable "pool_id" {
  description = "ID of the Workload Identity Pool"
  type        = string
  default     = "github-actions-pool"
}

variable "provider_id" {
  description = "ID of the Workload Identity Provider"
  type        = string
  default     = "github-provider"
}

variable "service_account_id" {
  description = "ID of the service account for GitHub Actions"
  type        = string
  default     = "github-actions-terraform"
}

variable "terraform_roles" {
  description = "List of IAM roles to grant to the GitHub Actions service account"
  type        = list(string)
  default = [
    # Compute & Storage
    "roles/compute.admin",
    "roles/storage.admin",
    # Observability
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/cloudtrace.admin",
    # Service Usage
    "roles/serviceusage.serviceUsageConsumer",
    # Event-Driven Architecture
    "roles/artifactregistry.admin",
    "roles/run.admin",
    "roles/pubsub.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
  ]
}
