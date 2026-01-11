output "bucket_name" {
  description = "Name of the created GCS bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "URL of the GCS bucket"
  value       = google_storage_bucket.terraform_state.url
}

output "bucket_self_link" {
  description = "Self link of the GCS bucket"
  value       = google_storage_bucket.terraform_state.self_link
}

output "backend_config" {
  description = "Backend configuration snippet to use in your Terraform code"
  value       = <<-EOT

    ========================================
    Backend Configuration
    ========================================

    Add this to your backend.tf files:

    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.terraform_state.name}"
        prefix = "terraform/<architecture>/<environment>"  # Customize this path
      }
    }

    Example prefixes:
    - terraform/microservices-gke/dev
    - terraform/event-driven/prod
    - terraform/workflow-batch/dev

    ========================================
  EOT
}

output "setup_complete" {
  description = "Confirmation message"
  value       = <<-EOT

    ✅ Terraform state bucket created successfully!

    Bucket: ${google_storage_bucket.terraform_state.name}
    Location: ${google_storage_bucket.terraform_state.location}
    Versioning: ${var.versioning_enabled ? "Enabled" : "Disabled"}

    Next steps:
    1. Update backend.tf files in each architecture
    2. Run 'terraform init' to migrate state to GCS
    3. Verify state is stored in the bucket

  EOT
}
