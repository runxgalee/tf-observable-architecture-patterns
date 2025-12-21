# Pub/Sub Outputs
output "topic_name" {
  description = "Pub/Sub topic name"
  value       = google_pubsub_topic.event_topic.name
}

output "topic_id" {
  description = "Pub/Sub topic ID"
  value       = google_pubsub_topic.event_topic.id
}

output "dead_letter_topic_name" {
  description = "Dead letter topic name"
  value       = google_pubsub_topic.dead_letter_topic.name
}

output "dead_letter_topic_id" {
  description = "Dead letter topic ID"
  value       = google_pubsub_topic.dead_letter_topic.id
}

output "subscription_name" {
  description = "Pub/Sub subscription name"
  value       = google_pubsub_subscription.event_subscription.name
}

output "subscription_id" {
  description = "Pub/Sub subscription ID"
  value       = google_pubsub_subscription.event_subscription.id
}

output "dead_letter_subscription_name" {
  description = "Dead letter subscription name"
  value       = google_pubsub_subscription.dead_letter_subscription.name
}

# Cloud Run Outputs
output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.event_processor.name
}

output "cloud_run_service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.event_processor.id
}

output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.event_processor.uri
}

output "cloud_run_location" {
  description = "Cloud Run service location"
  value       = google_cloud_run_v2_service.event_processor.location
}

# Service Account Outputs
output "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  value       = google_service_account.cloud_run_sa.email
}

output "cloud_run_service_account_id" {
  description = "Cloud Run service account ID"
  value       = google_service_account.cloud_run_sa.id
}

output "pubsub_service_account_email" {
  description = "Pub/Sub service account email"
  value       = google_service_account.pubsub_sa.email
}

output "pubsub_service_account_id" {
  description = "Pub/Sub service account ID"
  value       = google_service_account.pubsub_sa.id
}

# Project Information
output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP project number"
  value       = data.google_project.project.number
}

# Monitoring Outputs
output "alert_policy_ids" {
  description = "List of alert policy IDs"
  value = concat(
    var.enable_monitoring ? [google_monitoring_alert_policy.dead_letter_messages[0].id] : [],
    var.enable_monitoring ? [google_monitoring_alert_policy.high_error_rate[0].id] : [],
    var.enable_monitoring ? [google_monitoring_alert_policy.old_unacked_messages[0].id] : [],
    var.enable_monitoring && var.enable_error_reporting_metric ? [google_monitoring_alert_policy.error_reporting_alert[0].id] : []
  )
}

# Observability Outputs
output "monitoring_dashboard_url" {
  description = "URL to the Cloud Monitoring dashboard"
  value = var.enable_observability_dashboard ? "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.event_driven_dashboard[0].id}?project=${var.project_id}" : null
}

output "error_reporting_url" {
  description = "URL to the Cloud Error Reporting console"
  value       = "https://console.cloud.google.com/errors?project=${var.project_id}&service=${google_cloud_run_v2_service.event_processor.name}"
}

output "cloud_trace_url" {
  description = "URL to the Cloud Trace console"
  value       = var.enable_cloud_trace ? "https://console.cloud.google.com/traces/list?project=${var.project_id}" : null
}

output "cloud_logging_url" {
  description = "URL to Cloud Logging for the Cloud Run service"
  value       = "https://console.cloud.google.com/logs/query;query=resource.type%3D%22cloud_run_revision%22%0Aresource.labels.service_name%3D%22${google_cloud_run_v2_service.event_processor.name}%22?project=${var.project_id}"
}

output "observability_enabled" {
  description = "Observability features that are enabled"
  value = {
    dashboard       = var.enable_observability_dashboard
    error_reporting = var.enable_error_reporting_metric
    cloud_trace     = var.enable_cloud_trace
    error_log_sink  = var.enable_error_log_sink
  }
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
