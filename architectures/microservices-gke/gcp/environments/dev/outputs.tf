# GKE Cluster Outputs
output "cluster_name" {
  description = "GKE cluster name"
  value       = module.microservices_gke.cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.microservices_gke.cluster_endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = module.microservices_gke.cluster_location
}

# Network Outputs
output "network_name" {
  description = "VPC network name"
  value       = module.microservices_gke.network_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = module.microservices_gke.subnet_name
}

# Ingress Outputs
output "ingress_ip_address" {
  description = "Static IP address for Ingress"
  value       = module.microservices_gke.ingress_ip_address
}

output "ssl_certificate_name" {
  description = "Managed SSL certificate name"
  value       = module.microservices_gke.ssl_certificate_name
}

# Workload Identity Outputs
output "service_accounts" {
  description = "Map of created service accounts"
  value       = module.microservices_gke.service_accounts
}

# Operational Commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.microservices_gke.kubectl_config_command
}

output "deploy_command" {
  description = "Example kubectl apply command for deploying manifests"
  value       = module.microservices_gke.deploy_command
}
