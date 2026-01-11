# Terraform State GCS Bucket Setup

This directory contains Terraform configuration to create a Google Cloud Storage (GCS) bucket for storing Terraform state files remotely.

## Why Remote State?

Storing Terraform state in a remote backend (GCS) provides:

- **Team Collaboration**: Multiple team members can work on the same infrastructure
- **State Locking**: Prevents concurrent modifications
- **Versioning**: Keeps history of state changes
- **Security**: Centralized access control
- **CI/CD Integration**: GitHub Actions can access the same state

## Prerequisites

1. **GCP Project**: A GCP project where you want to store state
2. **GCP Permissions**: You need permissions to create GCS buckets
   - `roles/storage.admin` or similar
3. **gcloud CLI**: Installed and authenticated
   ```bash
   gcloud auth application-default login
   ```
4. **Terraform**: Version 1.13.0 or higher

## Setup Instructions

### Step 1: Configure Variables

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   project_id  = "tf-architecture-patterns"
   bucket_name = "tf-architecture-patterns-tfstate"  # Must be globally unique!

   # Optional: Get from github-actions-auth output
   github_actions_service_account = "github-actions-terraform@tf-architecture-patterns.iam.gserviceaccount.com"
   ```

   **Important**: The `bucket_name` must be **globally unique** across all GCP projects.

### Step 2: Initialize and Apply

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Create the bucket:
   ```bash
   terraform apply
   ```

4. Save the bucket name from the output:
   ```bash
   terraform output bucket_name
   ```

### Step 3: Update Backend Configuration

After creating the state bucket, update the `backend.tf` files in each architecture:

**Example**: `architectures/microservices-gke/gcp/environments/dev/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "tf-architecture-patterns-tfstate"  # From terraform output
    prefix = "terraform/microservices-gke/dev"
  }
}
```

**Prefix naming convention**:
- Format: `terraform/<architecture>/<environment>`
- Examples:
  - `terraform/microservices-gke/dev`
  - `terraform/event-driven/prod`
  - `terraform/workflow-batch/dev`

### Step 4: Migrate Existing State (if any)

If you have local state files, migrate them to GCS:

```bash
cd architectures/microservices-gke/gcp/environments/dev

# This will prompt to copy existing state to GCS
terraform init -migrate-state
```

## What Gets Created

This Terraform configuration creates:

1. **GCS Bucket**:
   - Uniform bucket-level access enabled
   - Versioning enabled (keeps history)
   - Lifecycle policy to delete old versions after 30 days
   - `prevent_destroy` lifecycle to avoid accidental deletion

2. **IAM Permissions** (if service account provided):
   - `roles/storage.objectAdmin` for the GitHub Actions service account
   - `roles/storage.legacyBucketWriter` for state locking

## Security Features

- **Uniform Bucket-Level Access**: Simplifies permission management
- **Versioning**: Protects against accidental state corruption
- **Prevent Destroy**: Terraform won't delete the bucket accidentally
- **IAM-based Access**: Only authorized service accounts can access

## Bucket Structure

The state files will be organized as:

```
gs://tf-architecture-patterns-tfstate/
├── terraform/
│   ├── microservices-gke/
│   │   ├── dev/
│   │   │   └── default.tfstate
│   │   └── prod/
│   │       └── default.tfstate
│   ├── event-driven/
│   │   ├── dev/
│   │   │   └── default.tfstate
│   │   └── prod/
│   │       └── default.tfstate
│   └── workflow-batch/
│       ├── dev/
│       │   └── default.tfstate
│       └── prod/
│           └── default.tfstate
```

## Verification

After setup, verify the bucket:

```bash
# List the bucket
gcloud storage ls gs://tf-architecture-patterns-tfstate/

# Check versioning
gcloud storage buckets describe gs://tf-architecture-patterns-tfstate/ \
  --format="value(versioning.enabled)"

# Check IAM policy
gcloud storage buckets get-iam-policy gs://tf-architecture-patterns-tfstate/
```

## State Locking

GCS backend automatically provides state locking using GCS object metadata. No additional configuration needed.

## Troubleshooting

### Bucket Name Already Exists

If you get an error about bucket name already existing:

1. Choose a different `bucket_name` in `terraform.tfvars`
2. Bucket names must be globally unique across all GCP

### Permission Denied

If you get permission errors:

```bash
# Verify you have the right permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"
```

You need at least `roles/storage.admin` or `roles/editor`.

### GitHub Actions Can't Access State

If GitHub Actions fails with permission errors:

1. Verify the service account email is correct
2. Check IAM bindings:
   ```bash
   gcloud storage buckets get-iam-policy gs://BUCKET_NAME
   ```
3. Re-apply this Terraform with the correct `github_actions_service_account`

## Cleanup

**⚠️ WARNING**: Deleting the state bucket will lose all infrastructure state!

If you really need to delete:

1. First remove the `prevent_destroy` lifecycle in `main.tf`
2. Then run:
   ```bash
   terraform destroy
   ```

## Best Practices

1. **Backup**: The bucket has versioning enabled - you can restore previous versions
2. **Separate Environments**: Use different prefixes for dev/prod
3. **Access Control**: Grant minimal permissions (don't use `allUsers`)
4. **Monitoring**: Enable GCS audit logs to track state changes

## References

- [Terraform GCS Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [GCS Bucket Versioning](https://cloud.google.com/storage/docs/object-versioning)
- [Terraform State Best Practices](https://developer.hashicorp.com/terraform/language/state/remote)
