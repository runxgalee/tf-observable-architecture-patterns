# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# Dependencies from service_accounts module
variable "cloud_run_service_account_email" {
  description = "Email of the Cloud Run service account (from service_accounts module)"
  type        = string
}

variable "pubsub_service_account_email" {
  description = "Email of the Pub/Sub service account (from service_accounts module)"
  type        = string
}

# Dependencies from cloudrun module
variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service (from cloudrun module)"
  type        = string
}

variable "cloud_run_service_location" {
  description = "Location of the Cloud Run service (from cloudrun module)"
  type        = string
}

# Dependencies from pubsub module
variable "dead_letter_topic_name" {
  description = "Name of the dead letter Pub/Sub topic (from pubsub module)"
  type        = string
}

variable "event_subscription_name" {
  description = "Name of the event Pub/Sub subscription (from pubsub module)"
  type        = string
}

# IAM Configuration
variable "enable_cloud_trace" {
  description = "Enable Cloud Trace for distributed tracing"
  type        = bool
}

variable "enable_error_reporting_metric" {
  description = "Enable Error Reporting metric"
  type        = bool
}

variable "enable_custom_metrics" {
  description = "Enable custom log-based metrics"
  type        = bool
}

variable "cloud_run_additional_roles" {
  description = "Additional IAM roles to grant to Cloud Run service account"
  type        = list(string)
}
