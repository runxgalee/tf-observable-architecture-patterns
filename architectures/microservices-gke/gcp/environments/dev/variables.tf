# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for resources"
  type        = string
  default     = "asia-northeast1"
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
  description = "Kubernetes version for GKE cluster"
  type        = string
  default     = ""
}

variable "release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
}

variable "enable_private_cluster" {
  description = "Enable private GKE cluster"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
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
  description = "Start time for maintenance window"
  type        = string
  default     = ""
}

variable "maintenance_window_duration" {
  description = "Duration of maintenance window"
  type        = string
  default     = "4h"
}

variable "maintenance_window_recurrence" {
  description = "Recurrence rule for maintenance window"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}

# Network Configuration
variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for services"
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
  description = "List of domains for managed SSL certificate"
  type        = list(string)
  default     = []
}

variable "enable_managed_ssl" {
  description = "Enable Google-managed SSL certificate"
  type        = bool
  default     = false
}

# Workload Identity Configuration
variable "enable_workload_identity" {
  description = "Enable Workload Identity for GKE"
  type        = bool
  default     = true
}

variable "workload_identity_namespace" {
  description = "Kubernetes namespace for Workload Identity"
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
  default = {
    backend = {
      display_name        = "Backend Service Account"
      k8s_service_account = "backend-sa"
      k8s_namespace       = "default"
      roles = [
        "roles/cloudsql.client",
        "roles/secretmanager.secretAccessor"
      ]
    }
    frontend = {
      display_name        = "Frontend Service Account"
      k8s_service_account = "frontend-sa"
      k8s_namespace       = "default"
      roles = [
        "roles/secretmanager.secretAccessor"
      ]
    }
  }
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
  description = "GKE logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "GKE monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "pod_restart_threshold" {
  description = "Threshold for pod restart alert"
  type        = number
  default     = 5
}

variable "node_cpu_threshold" {
  description = "Threshold for node CPU alert"
  type        = number
  default     = 80
}

variable "node_memory_threshold" {
  description = "Threshold for node memory alert"
  type        = number
  default     = 80
}

variable "pod_pending_threshold" {
  description = "Threshold for pending pods alert"
  type        = number
  default     = 5
}
