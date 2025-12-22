# GKE Cluster Outputs
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.primary.location
}

# Network Outputs
output "network_name" {
  description = "VPC network name"
  value       = local.network_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = local.subnet_name
}

# Ingress Outputs
output "ingress_ip_address" {
  description = "Static IP address for Ingress"
  value       = var.enable_ingress ? google_compute_global_address.ingress[0].address : null
}

output "ssl_certificate_name" {
  description = "Managed SSL certificate name"
  value       = var.enable_ingress && var.enable_managed_ssl && length(var.ssl_certificate_domains) > 0 ? google_compute_managed_ssl_certificate.default[0].name : null
}

# Workload Identity Outputs
output "service_accounts" {
  description = "Map of created service accounts"
  value = {
    for k, v in google_service_account.workload_identity : k => {
      email = v.email
      name  = v.name
    }
  }
}

# Kubectl Configuration Command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region=${var.region} --project=${var.project_id}"
}

# Deploy Command
output "deploy_command" {
  description = "Example kubectl apply command for deploying manifests"
  value       = "kubectl apply -k k8s/overlays/${var.environment}"
}
