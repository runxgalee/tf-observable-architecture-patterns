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

### Step 3: Configure Backend for Architecture Patterns

After creating the state bucket, configure the backend using **partial backend configuration** (recommended):

1. **Create `backend.hcl`** in each architecture pattern directory (git-ignored):

   ```bash
   cd architectures/<pattern>/gcp
   cp backend.hcl.example backend.hcl
   ```

2. **Edit `backend.hcl`** with the bucket name from terraform output:

   ```hcl
   bucket = "tf-architecture-patterns-tfstate"  # From terraform output
   prefix = "terraform/<pattern>/state"
   ```

3. **Initialize with backend config**:

   ```bash
   terraform init -backend-config=backend.hcl
   ```

**Prefix naming convention**:
- Format: `terraform/<pattern>/state`
- Examples:
  - `terraform/event-driven/state`
  - `terraform/microservices-gke/state` (future)
  - `terraform/workflow-batch/state` (future)

**Note**: Environment separation is handled via `.auto.tfvars` files (e.g., `dev.auto.tfvars`), not separate directories

### Step 4: Migrate Existing State (if any)

If you have local state files, migrate them to GCS:

```bash
cd architectures/<pattern>/gcp

# Create backend.hcl first (see Step 3)

# This will prompt to copy existing state to GCS
terraform init -backend-config=backend.hcl -migrate-state
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
└── terraform/
    ├── event-driven/
    │   └── state/
    │       └── default.tfstate
    ├── microservices-gke/  # Future pattern
    │   └── state/
    │       └── default.tfstate
    └── workflow-batch/     # Future pattern
        └── state/
            └── default.tfstate
```

**Note**: Each pattern stores one state file. Environment-specific configuration is managed through `.auto.tfvars` files (e.g., `dev.auto.tfvars`, `prod.auto.tfvars`), not separate state files

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

## Next Steps

After setting up the Terraform state bucket:

1. **Configure Secret Manager** (`bootstrap/gcp/secrets/`):
   - Create secrets for state bucket names
   - Store other CI/CD secrets
   - See `bootstrap/gcp/secrets/README.md`

2. **Configure Architecture Patterns**:
   - Create `backend.hcl` in each pattern (e.g., `architectures/event-driven/gcp/`)
   - Initialize with: `terraform init -backend-config=backend.hcl`
   - See `docs/backend-setup.md` for details

## References

- [Terraform GCS Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [GCS Bucket Versioning](https://cloud.google.com/storage/docs/object-versioning)
- [Terraform State Best Practices](https://developer.hashicorp.com/terraform/language/state/remote)
- [Partial Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration#partial-configuration)
