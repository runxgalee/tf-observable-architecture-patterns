# Microservices GKE Architecture - Development Environment

module "microservices_gke" {
  source = "../../modules/microservices-gke"

  # Project Configuration
  project_id   = var.project_id
  region       = var.region
  environment  = "dev"
  project_name = var.project_name

  # GKE Configuration
  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  release_channel               = var.release_channel
  enable_private_cluster        = var.enable_private_cluster
  master_ipv4_cidr_block        = var.master_ipv4_cidr_block
  master_authorized_networks    = var.master_authorized_networks
  enable_binary_authorization   = var.enable_binary_authorization
  enable_shielded_nodes         = var.enable_shielded_nodes
  maintenance_window_start_time = var.maintenance_window_start_time
  maintenance_window_duration   = var.maintenance_window_duration
  maintenance_window_recurrence = var.maintenance_window_recurrence

  # Network Configuration
  network_name  = var.network_name
  subnet_name   = var.subnet_name
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  # Ingress Configuration
  enable_ingress          = var.enable_ingress
  ingress_ip_name         = var.ingress_ip_name
  ssl_certificate_domains = var.ssl_certificate_domains
  enable_managed_ssl      = var.enable_managed_ssl

  # Workload Identity Configuration
  enable_workload_identity    = var.enable_workload_identity
  workload_identity_namespace = var.workload_identity_namespace
  service_accounts            = var.service_accounts

  # Monitoring Configuration
  enable_monitoring     = var.enable_monitoring
  enable_logging        = var.enable_logging
  logging_components    = var.logging_components
  monitoring_components = var.monitoring_components
  notification_channels = var.notification_channels
  pod_restart_threshold = var.pod_restart_threshold
  node_cpu_threshold    = var.node_cpu_threshold
  node_memory_threshold = var.node_memory_threshold
  pod_pending_threshold = var.pod_pending_threshold
}
