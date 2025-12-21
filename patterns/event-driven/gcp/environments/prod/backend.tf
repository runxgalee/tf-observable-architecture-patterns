# Backend configuration for Terraform state
# IMPORTANT: For production, always use a remote backend with state locking

terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "terraform/event-driven/prod"
  }
}

# Before running terraform init, create the GCS bucket:
# gcloud storage buckets create gs://your-terraform-state-bucket \
#   --project=your-project-id \
#   --location=asia-northeast1 \
#   --uniform-bucket-level-access

# Enable versioning for state file backup:
# gcloud storage buckets update gs://your-terraform-state-bucket --versioning
