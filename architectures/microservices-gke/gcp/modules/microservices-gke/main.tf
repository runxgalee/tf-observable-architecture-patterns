# Data source to get project number
data "google_project" "project" {
  project_id = var.project_id
}

# Local variables for common tags and naming
locals {
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  }

  resource_prefix = "${var.environment}-${var.project_name}"
}
