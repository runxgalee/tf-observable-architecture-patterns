# Backend configuration for Terraform state
# Actual bucket name is configured in backend.hcl (git-ignored)
# Initialize with: terraform init -backend-config=backend.hcl

terraform {
  backend "gcs" {
    # Configured via backend.hcl
    # bucket = "configured-in-backend-hcl"
    # prefix = "configured-in-backend-hcl"
  }
}
