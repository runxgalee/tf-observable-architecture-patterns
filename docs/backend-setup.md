# Terraform Remote State Setup Guide

This guide explains how to configure Terraform remote state storage using Google Cloud Storage (GCS).

## Overview

All architectures in this repository use **partial backend configuration** for security:
- `backend.tf` files are in git (no sensitive values)
- `backend.hcl` files contain actual values (git-ignored, not in version control)
- GitHub Actions uses secrets to configure the backend

## Prerequisites

1. GCP project with appropriate permissions
2. GCS bucket for Terraform state (see [Creating State Bucket](#creating-state-bucket))
3. Proper authentication configured (see `bootstrap/gcp/github-actions-auth/`)

## Creating State Bucket

### Option 1: Using Terraform (Recommended)

```bash
cd bootstrap/gcp/terraform-state

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Create the bucket
terraform init
terraform apply
```

### Option 2: Manual Creation

```bash
BUCKET_NAME="your-terraform-state-bucket"
PROJECT_ID="your-project-id"

gcloud storage buckets create gs://${BUCKET_NAME} \
  --project=${PROJECT_ID} \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

gcloud storage buckets update gs://${BUCKET_NAME} \
  --versioning
```

## Local Development Setup

For each architecture/environment you want to work with:

### 1. Create backend.hcl

```bash
cd architectures/microservices-gke/gcp/environments/dev

# Copy the example
cp backend.hcl.example backend.hcl

# Edit backend.hcl with your bucket name
# bucket = "your-terraform-state-bucket"
# prefix = "terraform/microservices-gke/dev"
```

### 2. Initialize Terraform

```bash
terraform init -backend-config=backend.hcl
```

### 3. Verify State

```bash
# Check that state is in GCS
gcloud storage ls gs://your-terraform-state-bucket/terraform/
```

## GitHub Actions Setup

### Required Secrets

Add the following secret to your GitHub repository:

**Repository → Settings → Secrets and variables → Actions**

1. **TF_STATE_BUCKET**
   - Name of the GCS bucket for Terraform state
   - Example: `tf-architecture-patterns-tfstate`

2. **WIF_PROVIDER** (already configured)
   - Workload Identity Provider for authentication

3. **WIF_SERVICE_ACCOUNT** (already configured)
   - Service account email for GitHub Actions

### How It Works

GitHub Actions workflows automatically configure the backend using:

```yaml
terraform init \
  -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
  -backend-config="prefix=terraform/${{ matrix.pattern }}/${{ matrix.environment }}"
```

The prefix is dynamically generated based on the architecture and environment being deployed.

## State Organization

States are organized in the bucket with this structure:

```
gs://your-terraform-state-bucket/
└── terraform/
    ├── microservices-gke/
    │   ├── dev/
    │   │   └── default.tfstate
    │   └── prod/
    │       └── default.tfstate
    ├── event-driven/
    │   ├── dev/
    │   │   └── default.tfstate
    │   └── prod/
    │       └── default.tfstate
    └── workflow-batch/
        ├── dev/
        │   └── default.tfstate
        └── prod/
            └── default.tfstate
```

## Migrating Existing Local State

If you have existing local state files, migrate them to GCS:

```bash
cd architectures/<architecture>/gcp/environments/<environment>

# Create backend.hcl first (see above)

# This will prompt you to copy existing state to GCS
terraform init -backend-config=backend.hcl -migrate-state

# Verify migration
terraform state list
```

## Security Best Practices

### ✅ DO

- Keep `backend.hcl` files out of version control
- Use unique bucket names per project
- Enable versioning on the state bucket
- Use Workload Identity Federation (no service account keys)
- Restrict bucket access with IAM

### ❌ DON'T

- Commit `backend.hcl` files to git
- Share state buckets across unrelated projects
- Use service account keys for authentication
- Disable state locking

## Troubleshooting

### Error: "Backend configuration changed"

```bash
# Re-initialize with backend config
terraform init -reconfigure -backend-config=backend.hcl
```

### Error: "Failed to get existing workspaces"

Check that:
1. Bucket name is correct in `backend.hcl` or secrets
2. Service account has access to the bucket
3. Bucket exists in the specified project

```bash
# Verify bucket exists
gcloud storage ls gs://your-bucket-name/

# Check IAM permissions
gcloud storage buckets get-iam-policy gs://your-bucket-name/
```

### Error: "Error locking state"

Another process may be running terraform. Wait for it to complete or:

```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### GitHub Actions: "Error configuring the backend"

1. Verify `TF_STATE_BUCKET` secret is set in GitHub
2. Check that the service account has `roles/storage.objectAdmin` on the bucket
3. Ensure Workload Identity is properly configured

## State Locking

GCS backend automatically provides state locking using object metadata. No additional configuration needed.

Lock timeout: 10 minutes (default)

## Backup and Recovery

### Automatic Backups

State versioning is enabled on the bucket. To restore a previous version:

```bash
# List versions
gcloud storage ls -a gs://your-bucket/terraform/microservices-gke/dev/

# Download a specific version
gcloud storage cp gs://your-bucket/terraform/microservices-gke/dev/default.tfstate#<generation> ./backup.tfstate
```

### Manual Backup

```bash
# Download current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate
```

## References

- [Terraform GCS Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [GCS Versioning](https://cloud.google.com/storage/docs/object-versioning)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)
