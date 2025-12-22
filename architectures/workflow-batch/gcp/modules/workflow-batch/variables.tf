variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "service_name" {
  description = "Service name prefix"
  type        = string
  default     = "workflow-batch"
}

# Cloud Scheduler variables
variable "scheduler_schedule" {
  description = "Cron schedule for Cloud Scheduler (e.g., '0 9 * * *' for daily at 9:00 AM JST)"
  type        = string
  default     = "0 9 * * *"
}

variable "scheduler_time_zone" {
  description = "Time zone for scheduler"
  type        = string
  default     = "Asia/Tokyo"
}

variable "scheduler_description" {
  description = "Description for Cloud Scheduler job"
  type        = string
  default     = "Trigger workflow batch processing"
}

# Cloud Run Job variables
variable "job_task_count" {
  description = "Number of tasks to run in parallel"
  type        = number
  default     = 1
}

variable "job_max_retries" {
  description = "Maximum number of retries for failed tasks"
  type        = number
  default     = 3
}

variable "job_timeout" {
  description = "Maximum execution time for each task (in seconds)"
  type        = string
  default     = "3600s"
}

variable "job_cpu" {
  description = "CPU allocation for each task"
  type        = string
  default     = "1000m"
}

variable "job_memory" {
  description = "Memory allocation for each task"
  type        = string
  default     = "512Mi"
}

variable "job_image" {
  description = "Container image for Cloud Run Job"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "job_env_vars" {
  description = "Environment variables for the job"
  type        = map(string)
  default     = {}
}

# Monitoring variables
variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

variable "job_failure_threshold" {
  description = "Number of consecutive failures before alerting"
  type        = number
  default     = 2
}

# Labels
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
