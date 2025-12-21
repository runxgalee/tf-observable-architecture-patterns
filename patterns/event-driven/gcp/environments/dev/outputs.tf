# Output values from the event-driven module

output "topic_name" {
  description = "Pub/Sub topic name"
  value       = module.event_driven.topic_name
}

output "subscription_name" {
  description = "Pub/Sub subscription name"
  value       = module.event_driven.subscription_name
}

output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.event_driven.cloud_run_url
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = module.event_driven.cloud_run_service_name
}

output "service_account_email" {
  description = "Cloud Run service account email"
  value       = module.event_driven.cloud_run_service_account_email
}

output "dead_letter_topic_name" {
  description = "Dead letter topic name"
  value       = module.event_driven.dead_letter_topic_name
}

output "configuration_summary" {
  description = "Configuration summary"
  value       = module.event_driven.configuration_summary
}

# Instructions for publishing test messages
output "publish_test_message_command" {
  description = "Command to publish a test message"
  value       = "gcloud pubsub topics publish ${module.event_driven.topic_name} --message='{\"event_type\":\"test\",\"data\":\"Hello from dev!\"}'"
}

# Instructions for viewing logs
output "view_logs_command" {
  description = "Command to view Cloud Run logs"
  value       = "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=${module.event_driven.cloud_run_service_name}\" --limit 50 --format json"
}
