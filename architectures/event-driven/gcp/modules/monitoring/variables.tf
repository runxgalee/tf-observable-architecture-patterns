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

variable "dead_letter_subscription_name" {
  description = "Name of the dead letter subscription (from pubsub module)"
  type        = string
}

variable "event_subscription_name" {
  description = "Name of the event subscription (from pubsub module)"
  type        = string
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring alerts"
  type        = bool
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
}

variable "dlq_alert_threshold" {
  description = "Threshold for dead letter queue alert (number of messages)"
  type        = number
}

variable "error_rate_threshold" {
  description = "Threshold for error rate alert (errors per second)"
  type        = number
}

variable "oldest_unacked_message_age_threshold" {
  description = "Threshold for oldest unacked message age alert (seconds)"
  type        = number
}

variable "max_delivery_attempts" {
  description = "Maximum number of delivery attempts (used in alert documentation)"
  type        = number
}

variable "enable_custom_metrics" {
  description = "Enable custom log-based metrics"
  type        = bool
}
