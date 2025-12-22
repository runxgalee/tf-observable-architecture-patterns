# Backend configuration for Terraform state
# Uncomment and configure to use GCS backend for state storage

# terraform {
#   backend "gcs" {
#     bucket = "your-terraform-state-bucket"
#     prefix = "terraform/event-driven/dev"
#   }
# }

# For local development, state will be stored locally as terraform.tfstate
# In production, it's recommended to use a remote backend like GCS
