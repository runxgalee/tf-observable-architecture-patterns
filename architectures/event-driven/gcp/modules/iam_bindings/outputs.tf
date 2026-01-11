# Project Information
output "project_number" {
  description = "GCP project number"
  value       = data.google_project.project.number
}
