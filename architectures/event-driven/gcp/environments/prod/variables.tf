# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "events"
}

# Pub/Sub Configuration
variable "topic_name" {
  description = "Pub/Sub topic name"
  type        = string
  default     = "events"
}

variable "message_retention_duration" {
  description = "Message retention duration"
  type        = string
  default     = "86400s"
}

variable "ack_deadline_seconds" {
  description = "Acknowledgement deadline in seconds"
  type        = number
  default     = 60
}

variable "retry_minimum_backoff" {
  description = "Minimum backoff for retry"
  type        = string
  default     = "10s"
}

variable "retry_maximum_backoff" {
  description = "Maximum backoff for retry"
  type        = string
  default     = "600s"
}

variable "max_delivery_attempts" {
  description = "Maximum delivery attempts"
  type        = number
  default     = 5
}

variable "subscription_message_retention_duration" {
  description = "Subscription message retention duration"
  type        = string
  default     = "604800s"
}

variable "enable_exactly_once_delivery" {
  description = "Enable exactly once delivery"
  type        = bool
  default     = true
}

# Cloud Run Configuration
variable "container_image" {
  description = "Container image for Cloud Run"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
}

variable "concurrency" {
  description = "Concurrent requests per instance"
  type        = number
  default     = 80
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "2"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "1Gi"
}

variable "cpu_always_allocated" {
  description = "Keep CPU allocated"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Enable CPU boost during startup"
  type        = bool
  default     = true
}

variable "request_timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"
}

variable "additional_env_vars" {
  description = "Additional environment variables"
  type        = map(string)
  default     = {}
}

variable "enable_health_check" {
  description = "Enable health check"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

# VPC Configuration
variable "vpc_connector_name" {
  description = "VPC Connector name"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}

# IAM Configuration
variable "cloud_run_additional_roles" {
  description = "Additional IAM roles"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channel IDs"
  type        = list(string)
}

variable "dlq_alert_threshold" {
  description = "DLQ alert threshold"
  type        = number
  default     = 0
}

variable "error_rate_threshold" {
  description = "Error rate threshold"
  type        = number
  default     = 5
}

variable "oldest_unacked_message_age_threshold" {
  description = "Oldest unacked message age threshold"
  type        = number
  default     = 300
}

variable "enable_custom_metrics" {
  description = "Enable custom metrics"
  type        = bool
  default     = true
}
