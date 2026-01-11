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
variable "service_account_email" {
  description = "Email of the service account for Cloud Run (from iam module)"
  type        = string
}

# Cloud Run Configuration
variable "container_image" {
  description = "Container image for Cloud Run service"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
}

variable "concurrency" {
  description = "Maximum number of concurrent requests per Cloud Run instance"
  type        = number
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run container"
  type        = string
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run container"
  type        = string
}

variable "cpu_always_allocated" {
  description = "Keep CPU allocated even when container is idle"
  type        = bool
}

variable "startup_cpu_boost" {
  description = "Enable CPU boost during startup"
  type        = bool
}

variable "request_timeout" {
  description = "Request timeout in seconds for Cloud Run"
  type        = number
}

variable "log_level" {
  description = "Log level for the application"
  type        = string
}

variable "additional_env_vars" {
  description = "Additional environment variables for Cloud Run"
  type        = map(string)
}

variable "enable_health_check" {
  description = "Enable health check probes for Cloud Run"
  type        = bool
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
}

# VPC Configuration
variable "vpc_connector_name" {
  description = "VPC Connector name for Cloud Run"
  type        = string
}

variable "vpc_egress" {
  description = "VPC egress setting"
  type        = string
}

# Observability Configuration
variable "enable_cloud_trace" {
  description = "Enable Cloud Trace for distributed tracing"
  type        = bool
}

variable "trace_sampling_rate" {
  description = "Trace sampling rate (0.0 to 1.0)"
  type        = number
}

variable "enable_error_reporting_metric" {
  description = "Enable Error Reporting metric"
  type        = bool
}
