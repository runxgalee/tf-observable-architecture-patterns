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
  sensitive   = true # Sensitive in production
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

output "alert_policy_ids" {
  description = "Alert policy IDs"
  value       = module.event_driven.alert_policy_ids
}

# Production monitoring commands
output "monitoring_commands" {
  description = "Useful monitoring commands for production"
  value = {
    view_logs        = "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=${module.event_driven.cloud_run_service_name}\" --limit 50 --format json"
    check_dlq        = "gcloud pubsub subscriptions pull ${module.event_driven.dead_letter_topic_name}-subscription --limit=10"
    check_metrics    = "gcloud monitoring time-series list --filter='metric.type=\"run.googleapis.com/request_count\" AND resource.labels.service_name=\"${module.event_driven.cloud_run_service_name}\"'"
    describe_service = "gcloud run services describe ${module.event_driven.cloud_run_service_name} --region=${var.region}"
  }
}
