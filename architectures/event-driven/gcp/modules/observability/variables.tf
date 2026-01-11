# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

# Dependencies from other modules
variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service (from cloudrun module)"
  type        = string
}

variable "event_topic_name" {
  description = "Name of the event Pub/Sub topic (from pubsub module)"
  type        = string
}

variable "event_subscription_name" {
  description = "Name of the event subscription (from pubsub module)"
  type        = string
}

variable "dead_letter_subscription_name" {
  description = "Name of the dead letter subscription (from pubsub module)"
  type        = string
}

# Observability Configuration
variable "enable_observability_dashboard" {
  description = "Enable Cloud Monitoring dashboard for event-driven architecture"
  type        = bool
}

variable "enable_error_reporting_metric" {
  description = "Enable log-based metric for Error Reporting"
  type        = bool
}

variable "error_reporting_threshold" {
  description = "Threshold for error reporting alert (errors per second)"
  type        = number
}

variable "enable_cloud_trace" {
  description = "Enable Cloud Trace for distributed tracing"
  type        = bool
}

variable "enable_error_log_sink" {
  description = "Enable log sink to BigQuery for long-term error analysis"
  type        = bool
}

variable "error_log_dataset_id" {
  description = "BigQuery dataset ID for error log sink"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable monitoring alerts"
  type        = bool
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
}

variable "dlq_alert_threshold" {
  description = "Threshold for dead letter queue alert (used in dashboard)"
  type        = number
}
