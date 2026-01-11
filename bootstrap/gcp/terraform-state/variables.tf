variable "project_id" {
  description = "GCP Project ID where the Terraform state bucket will be created"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket for Terraform state (must be globally unique)"
  type        = string
}

variable "location" {
  description = "Location for the GCS bucket"
  type        = string
  default     = "asia-northeast1"
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"
}

variable "versioning_enabled" {
  description = "Enable versioning for state files"
  type        = bool
  default     = true
}

variable "lifecycle_age_days" {
  description = "Number of days after which to delete old versions (0 to disable)"
  type        = number
  default     = 30
}

variable "github_actions_service_account" {
  description = "Email of the GitHub Actions service account that needs access to the bucket"
  type        = string
  default     = ""
}
