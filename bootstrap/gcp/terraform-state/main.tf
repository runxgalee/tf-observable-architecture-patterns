# GCS Bucket for Terraform State
resource "google_storage_bucket" "terraform_state" {
  project       = var.project_id
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = false

  # Enable uniform bucket-level access (recommended for security)
  uniform_bucket_level_access = true

  # Enable versioning to keep history of state files
  versioning {
    enabled = var.versioning_enabled
  }

  # Lifecycle rule to delete old versions
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_age_days > 0 ? [1] : []
    content {
      condition {
        age                = var.lifecycle_age_days
        with_state         = "ARCHIVED"
        num_newer_versions = 3
      }
      action {
        type = "Delete"
      }
    }
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  labels = {
    purpose     = "terraform-state"
    managed-by  = "terraform"
    environment = "all"
  }
}

# Grant access to GitHub Actions service account if provided
resource "google_storage_bucket_iam_member" "github_actions_admin" {
  count  = var.github_actions_service_account != "" ? 1 : 0
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.github_actions_service_account}"
}

# Enable Object Versioning for state file protection
resource "google_storage_bucket_iam_member" "github_actions_legacy_writer" {
  count  = var.github_actions_service_account != "" ? 1 : 0
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${var.github_actions_service_account}"
}
