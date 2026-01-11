# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming (typically environment-project_name)"
  type        = string
}
