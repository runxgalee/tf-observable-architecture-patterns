# Data source to retrieve project number for Google-managed service accounts
data "google_project" "project" {
  project_id = var.project_id
}
