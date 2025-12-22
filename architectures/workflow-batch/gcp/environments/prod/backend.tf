# =============================================
# Terraform Backend Configuration (Production)
# =============================================
# Production environment uses GCS backend
# State file is stored in Google Cloud Storage
# =============================================
# Before running terraform init, create the GCS bucket:
# gcloud storage buckets create gs://your-terraform-state-bucket \
#   --project=your-prod-project-id \
#   --location=asia-northeast1 \
#   --uniform-bucket-level-access
# =============================================

terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket" # Replace with your bucket name
    prefix = "terraform/workflow-batch/prod"
  }
}
