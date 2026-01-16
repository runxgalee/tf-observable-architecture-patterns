# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
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
  description = "Message retention duration for Pub/Sub topic (e.g., '86400s' for 24 hours)"
  type        = string
  default     = "86400s"
}

variable "ack_deadline_seconds" {
  description = "Acknowledgement deadline in seconds for Pub/Sub subscription"
  type        = number
  default     = 60

  validation {
    condition     = var.ack_deadline_seconds >= 10 && var.ack_deadline_seconds <= 600
    error_message = "Ack deadline must be between 10 and 600 seconds."
  }
}

variable "retry_minimum_backoff" {
  description = "Minimum backoff duration for retry (e.g., '10s')"
  type        = string
  default     = "10s"
}

variable "retry_maximum_backoff" {
  description = "Maximum backoff duration for retry (e.g., '600s')"
  type        = string
  default     = "600s"
}

variable "max_delivery_attempts" {
  description = "Maximum number of delivery attempts before sending to dead letter queue"
  type        = number
  default     = 5

  validation {
    condition     = var.max_delivery_attempts >= 5 && var.max_delivery_attempts <= 100
    error_message = "Max delivery attempts must be between 5 and 100."
  }
}

variable "subscription_message_retention_duration" {
  description = "Message retention duration for subscription (e.g., '604800s' for 7 days)"
  type        = string
  default     = "604800s"
}

variable "enable_exactly_once_delivery" {
  description = "Enable exactly once delivery for Pub/Sub subscription"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances (0 to allow scaling to zero)"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 1000
    error_message = "Min instances must be between 0 and 1000."
  }
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 100

  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 1000
    error_message = "Max instances must be between 1 and 1000."
  }
}

variable "concurrency" {
  description = "Maximum number of concurrent requests per Cloud Run instance"
  type        = number
  default     = 80

  validation {
    condition     = var.concurrency >= 1 && var.concurrency <= 1000
    error_message = "Concurrency must be between 1 and 1000."
  }
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run container (e.g., '1', '2', '4')"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run container (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "512Mi"
}

variable "cpu_always_allocated" {
  description = "Keep CPU allocated even when container is idle"
  type        = bool
  default     = false
}

variable "startup_cpu_boost" {
  description = "Enable CPU boost during startup"
  type        = bool
  default     = true
}

variable "request_timeout" {
  description = "Request timeout in seconds for Cloud Run"
  type        = number
  default     = 300

  validation {
    condition     = var.request_timeout >= 1 && var.request_timeout <= 3600
    error_message = "Request timeout must be between 1 and 3600 seconds."
  }
}

variable "log_level" {
  description = "Log level for the application (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR."
  }
}

variable "additional_env_vars" {
  description = "Additional environment variables for Cloud Run"
  type        = map(string)
  default     = {}
}

variable "enable_health_check" {
  description = "Enable health check probes for Cloud Run"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

# VPC Configuration
variable "vpc_connector_name" {
  description = "VPC Connector name for Cloud Run (optional, leave empty to disable)"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting (ALL_TRAFFIC or PRIVATE_RANGES_ONLY)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "VPC egress must be either ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }
}

# IAM Configuration
variable "cloud_run_additional_roles" {
  description = "Additional IAM roles to grant to Cloud Run service account"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "dlq_alert_threshold" {
  description = "Threshold for dead letter queue alert (number of messages)"
  type        = number
  default     = 0
}

variable "error_rate_threshold" {
  description = "Threshold for error rate alert (errors per second)"
  type        = number
  default     = 5
}

variable "oldest_unacked_message_age_threshold" {
  description = "Threshold for oldest unacked message age alert (seconds)"
  type        = number
  default     = 300
}

variable "enable_custom_metrics" {
  description = "Enable custom log-based metrics"
  type        = bool
  default     = false
}

# Observability Configuration
variable "enable_observability_dashboard" {
  description = "Enable Cloud Monitoring dashboard for event-driven architecture"
  type        = bool
  default     = true
}

variable "enable_error_reporting_metric" {
  description = "Enable log-based metric for Error Reporting"
  type        = bool
  default     = true
}

variable "error_reporting_threshold" {
  description = "Threshold for error reporting alert (errors per second)"
  type        = number
  default     = 1
}

variable "enable_cloud_trace" {
  description = "Enable Cloud Trace for distributed tracing (requires application instrumentation)"
  type        = bool
  default     = true
}

variable "trace_sampling_rate" {
  description = "Trace sampling rate (0.0 to 1.0, where 1.0 means 100% sampling)"
  type        = number
  default     = 0.1

  validation {
    condition     = var.trace_sampling_rate >= 0 && var.trace_sampling_rate <= 1
    error_message = "Trace sampling rate must be between 0 and 1."
  }
}

variable "enable_error_log_sink" {
  description = "Enable log sink to BigQuery for long-term error analysis"
  type        = bool
  default     = false
}

variable "error_log_dataset_id" {
  description = "BigQuery dataset ID for error log sink (required if enable_error_log_sink is true)"
  type        = string
  default     = ""
}
