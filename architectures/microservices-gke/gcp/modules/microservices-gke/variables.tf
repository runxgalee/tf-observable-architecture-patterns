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
  default     = "microservices"
}

# GKE Configuration
variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "microservices"
}

variable "kubernetes_version" {
  description = "Kubernetes version for GKE cluster (e.g., '1.28', leave empty for latest)"
  type        = string
  default     = ""
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of: RAPID, REGULAR, STABLE."
  }
}

variable "enable_private_cluster" {
  description = "Enable private GKE cluster"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master (e.g., '172.16.0.0/28')"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks authorized to access GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for GKE"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE Nodes"
  type        = bool
  default     = true
}

variable "maintenance_window_start_time" {
  description = "Start time for maintenance window (e.g., '2024-01-01T00:00:00Z')"
  type        = string
  default     = ""
}

variable "maintenance_window_duration" {
  description = "Duration of maintenance window (e.g., '4h')"
  type        = string
  default     = "4h"
}

variable "maintenance_window_recurrence" {
  description = "Recurrence rule for maintenance window (e.g., 'FREQ=WEEKLY;BYDAY=SU')"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}

# Network Configuration
variable "network_name" {
  description = "VPC network name (leave empty to create new network)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name (leave empty to create new subnet)"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for subnet (e.g., '10.0.0.0/24')"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR block for pods (e.g., '10.1.0.0/16')"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for services (e.g., '10.2.0.0/16')"
  type        = string
  default     = "10.2.0.0/16"
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable Ingress with Google Cloud Load Balancer"
  type        = bool
  default     = true
}

variable "ingress_ip_name" {
  description = "Name for reserved static IP address for Ingress"
  type        = string
  default     = "ingress-ip"
}

variable "ssl_certificate_domains" {
  description = "List of domains for managed SSL certificate (e.g., ['example.com', 'www.example.com'])"
  type        = list(string)
  default     = []
}

variable "enable_managed_ssl" {
  description = "Enable Google-managed SSL certificate"
  type        = bool
  default     = true
}

# Workload Identity Configuration
variable "enable_workload_identity" {
  description = "Enable Workload Identity for GKE"
  type        = bool
  default     = true
}

variable "workload_identity_namespace" {
  description = "Kubernetes namespace for Workload Identity (e.g., 'default')"
  type        = string
  default     = "default"
}

variable "service_accounts" {
  description = "Map of service accounts to create with their Kubernetes service account bindings"
  type = map(object({
    display_name        = string
    k8s_service_account = string
    k8s_namespace       = string
    roles               = list(string)
  }))
  default = {}
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable Cloud Monitoring and Logging"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable Cloud Logging"
  type        = bool
  default     = true
}

variable "logging_components" {
  description = "GKE logging components to enable (SYSTEM_COMPONENTS, WORKLOADS)"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "GKE monitoring components to enable (SYSTEM_COMPONENTS, WORKLOADS)"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "pod_restart_threshold" {
  description = "Threshold for pod restart alert (number of restarts in 5 minutes)"
  type        = number
  default     = 5
}

variable "node_cpu_threshold" {
  description = "Threshold for node CPU alert (percentage)"
  type        = number
  default     = 80
}

variable "node_memory_threshold" {
  description = "Threshold for node memory alert (percentage)"
  type        = number
  default     = 80
}

variable "pod_pending_threshold" {
  description = "Threshold for pending pods alert (number of pods)"
  type        = number
  default     = 5
}
