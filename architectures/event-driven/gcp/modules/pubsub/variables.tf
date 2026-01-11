# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
}

# Dependencies from other modules
variable "push_endpoint" {
  description = "Cloud Run service URI for push subscription (from cloudrun module)"
  type        = string
}

variable "oidc_service_account_email" {
  description = "Service account email for OIDC token (from iam module)"
  type        = string
}

# Pub/Sub Configuration
variable "topic_name" {
  description = "Pub/Sub topic name"
  type        = string
}

variable "message_retention_duration" {
  description = "Message retention duration for Pub/Sub topic"
  type        = string
}

variable "ack_deadline_seconds" {
  description = "Acknowledgement deadline in seconds for Pub/Sub subscription"
  type        = number
}

variable "retry_minimum_backoff" {
  description = "Minimum backoff duration for retry"
  type        = string
}

variable "retry_maximum_backoff" {
  description = "Maximum backoff duration for retry"
  type        = string
}

variable "max_delivery_attempts" {
  description = "Maximum number of delivery attempts before sending to dead letter queue"
  type        = number
}

variable "subscription_message_retention_duration" {
  description = "Message retention duration for subscription"
  type        = string
}

variable "enable_exactly_once_delivery" {
  description = "Enable exactly once delivery for Pub/Sub subscription"
  type        = bool
}
