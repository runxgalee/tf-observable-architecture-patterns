variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the repository"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "repository_id" {
  description = "Repository ID (name)"
  type        = string
  default     = "cloudrun-images"
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = "Docker images for Cloud Run services"
}
