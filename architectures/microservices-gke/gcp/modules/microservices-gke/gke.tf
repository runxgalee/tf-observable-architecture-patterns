# VPC Network
resource "google_compute_network" "vpc" {
  count = var.network_name == "" ? 1 : 0

  name                    = "${local.resource_prefix}-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  count = var.subnet_name == "" ? 1 : 0

  name          = "${local.resource_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = local.network_name
  project       = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = true
}

# Local values for network references
locals {
  network_name = var.network_name != "" ? var.network_name : google_compute_network.vpc[0].name
  subnet_name  = var.subnet_name != "" ? var.subnet_name : google_compute_subnetwork.subnet[0].name
}

# GKE Autopilot Cluster
resource "google_container_cluster" "primary" {
  name     = "${local.resource_prefix}-${var.cluster_name}"
  location = var.region
  project  = var.project_id

  # Autopilot mode
  enable_autopilot = true

  # Network configuration
  network    = local.network_name
  subnetwork = local.subnet_name

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = var.subnet_name == "" ? "pods" : null
    services_secondary_range_name = var.subnet_name == "" ? "services" : null
  }

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.enable_private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = false
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Monitoring and logging
  monitoring_config {
    enable_components = var.enable_monitoring ? var.monitoring_components : []

    managed_prometheus {
      enabled = var.enable_monitoring
    }
  }

  logging_config {
    enable_components = var.enable_logging ? var.logging_components : []
  }

  # Binary Authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Maintenance window
  dynamic "maintenance_policy" {
    for_each = var.maintenance_window_start_time != "" ? [1] : []
    content {
      recurring_window {
        start_time = var.maintenance_window_start_time
        end_time   = timeadd(var.maintenance_window_start_time, var.maintenance_window_duration)
        recurrence = var.maintenance_window_recurrence
      }
    }
  }

  # Security and compliance
  enable_shielded_nodes = var.enable_shielded_nodes

  # Resource labels
  resource_labels = local.common_labels

  # Deletion protection
  deletion_protection = var.environment == "prod" ? true : false
}

# Static IP for Ingress
resource "google_compute_global_address" "ingress" {
  count = var.enable_ingress ? 1 : 0

  name    = "${local.resource_prefix}-${var.ingress_ip_name}"
  project = var.project_id
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  count = var.enable_ingress && var.enable_managed_ssl && length(var.ssl_certificate_domains) > 0 ? 1 : 0

  name    = "${local.resource_prefix}-ssl-cert"
  project = var.project_id

  managed {
    domains = var.ssl_certificate_domains
  }

  lifecycle {
    create_before_destroy = true
  }
}
