# Cloud Run Service Outputs
output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.event_processor.name
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.event_processor.id
}

output "service_uri" {
  description = "URI of the Cloud Run service"
  value       = google_cloud_run_v2_service.event_processor.uri
}

output "location" {
  description = "Location of the Cloud Run service"
  value       = google_cloud_run_v2_service.event_processor.location
}
