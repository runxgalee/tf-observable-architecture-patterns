# Pub/Sub Outputs
output "topic_name" {
  description = "Pub/Sub topic name"
  value       = module.pubsub.topic_name
}

output "topic_id" {
  description = "Pub/Sub topic ID"
  value       = module.pubsub.topic_id
}

output "dead_letter_topic_name" {
  description = "Dead letter topic name"
  value       = module.pubsub.dead_letter_topic_name
}

output "dead_letter_topic_id" {
  description = "Dead letter topic ID"
  value       = module.pubsub.dead_letter_topic_id
}

output "subscription_name" {
  description = "Pub/Sub subscription name"
  value       = module.pubsub.subscription_name
}

output "subscription_id" {
  description = "Pub/Sub subscription ID"
  value       = module.pubsub.subscription_id
}

output "dead_letter_subscription_name" {
  description = "Dead letter subscription name"
  value       = module.pubsub.dead_letter_subscription_name
}

# Cloud Run Outputs
output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = module.cloudrun.service_name
}

output "cloud_run_service_id" {
  description = "Cloud Run service ID"
  value       = module.cloudrun.service_id
}

output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.cloudrun.service_uri
}

output "cloud_run_location" {
  description = "Cloud Run service location"
  value       = module.cloudrun.location
}

# Service Account Outputs
output "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  value       = module.service_accounts.cloud_run_service_account_email
}

output "cloud_run_service_account_id" {
  description = "Cloud Run service account ID"
  value       = module.service_accounts.cloud_run_service_account_id
}

output "pubsub_service_account_email" {
  description = "Pub/Sub service account email"
  value       = module.service_accounts.pubsub_service_account_email
}

output "pubsub_service_account_id" {
  description = "Pub/Sub service account ID"
  value       = module.service_accounts.pubsub_service_account_id
}

# Project Information
output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP project number"
  value       = module.iam_bindings.project_number
}

# Monitoring Outputs
output "alert_policy_ids" {
  description = "List of alert policy IDs"
  value       = module.monitoring.alert_policy_ids
}

# Observability Outputs
output "monitoring_dashboard_url" {
  description = "URL to the Cloud Monitoring dashboard"
  value       = module.observability.dashboard_url
}

output "error_reporting_url" {
  description = "URL to the Cloud Error Reporting console"
  value       = module.observability.error_reporting_url
}

output "cloud_trace_url" {
  description = "URL to the Cloud Trace console"
  value       = module.observability.cloud_trace_url
}

output "cloud_logging_url" {
  description = "URL to Cloud Logging for the Cloud Run service"
  value       = module.observability.cloud_logging_url
}

output "observability_enabled" {
  description = "Observability features that are enabled"
  value       = module.observability.observability_enabled
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the deployed configuration"
  value = {
    environment        = var.environment
    project_name       = var.project_name
    region             = var.region
    min_instances      = var.min_instances
    max_instances      = var.max_instances
    concurrency        = var.concurrency
    cpu_limit          = var.cpu_limit
    memory_limit       = var.memory_limit
    monitoring_enabled = var.enable_monitoring
  }
}

# Instructions for publishing test messages
output "publish_test_message_command" {
  description = "Command to publish a test message"
  value       = "gcloud pubsub topics publish ${module.pubsub.topic_name} --message='{\"event_type\":\"test\",\"data\":\"Hello World!\"}'"
}

# Instructions for viewing logs
output "view_logs_command" {
  description = "Command to view Cloud Run logs"
  value       = "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=${module.cloudrun.service_name}\" --limit 50 --format json"
}
