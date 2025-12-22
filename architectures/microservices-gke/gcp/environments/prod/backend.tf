# Backend configuration for Terraform state
# IMPORTANT: Configure this for production to use remote state storage

terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "terraform/microservices-gke/prod"
  }
}

# Create the GCS bucket before using it:
# gcloud storage buckets create gs://your-terraform-state-bucket \
#   --project=your-prod-project-id \
#   --location=asia-northeast1 \
#   --uniform-bucket-level-access
