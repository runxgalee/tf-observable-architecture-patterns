# GitHub Actions Workload Identity Federation Setup

This directory contains Terraform configuration to set up Workload Identity Federation for GitHub Actions to authenticate with Google Cloud Platform.

## Overview

Workload Identity Federation allows GitHub Actions to authenticate to GCP without using long-lived service account keys (JSON credentials). This is more secure and follows Google's recommended best practices.

## Prerequisites

1. **GCP Project**: A GCP project where you want to deploy resources
2. **GCP Permissions**: You need the following permissions in the project:
   - `roles/iam.workloadIdentityPoolAdmin`
   - `roles/iam.serviceAccountAdmin`
   - `roles/resourcemanager.projectIamAdmin`
3. **gcloud CLI**: Installed and authenticated (`gcloud auth application-default login`)
4. **Terraform**: Version 1.13.0 or higher

## Setup Instructions

### Step 1: Configure Variables

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   project_id        = "your-gcp-project-id"
   github_repository = "owner/repository-name"  # e.g., "runxgalee/tf-observable-architecture-patterns"
   ```

### Step 2: Enable Required APIs

Enable the necessary GCP APIs:
```bash
gcloud config set project YOUR_PROJECT_ID

gcloud services enable iamcredentials.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable sts.googleapis.com
```

### Step 3: Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. After successful apply, Terraform will output the values you need for GitHub secrets.

### Step 4: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Add the following secrets (values from terraform output):

   - **WIF_PROVIDER**:
     ```
     projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
     ```

   - **WIF_SERVICE_ACCOUNT**:
     ```
     github-actions-terraform@PROJECT_ID.iam.gserviceaccount.com
     ```

   You can get these values by running:
   ```bash
   terraform output workload_identity_provider
   terraform output service_account_email
   ```

### Step 5: Verify Setup

Push a change to your repository and verify that GitHub Actions can authenticate to GCP successfully.

## What Gets Created

This Terraform configuration creates:

1. **Workload Identity Pool**: A pool for managing external identities
2. **Workload Identity Provider**: OIDC provider configured for GitHub Actions
3. **Service Account**: A service account for GitHub Actions to use
4. **IAM Bindings**:
   - Allows GitHub Actions to impersonate the service account
   - Grants necessary roles to the service account for Terraform operations

## Security Considerations

- The Workload Identity Provider is configured to only accept tokens from your specific GitHub repository
- The service account has limited permissions (only what's needed for Terraform)
- No long-lived credentials are created or stored

## Customization

### Adjust IAM Roles

To customize the roles granted to the service account, modify the `terraform_roles` variable in `terraform.tfvars`:

```hcl
terraform_roles = [
  "roles/compute.admin",
  "roles/storage.admin",
  # Add or remove roles as needed
]
```

### Restrict to Specific Branches

To allow only specific branches (e.g., `main`) to deploy, you can modify the `attribute_condition` in `main.tf`:

```hcl
attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.ref == 'refs/heads/main'"
```

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

## Troubleshooting

### Authentication Error in GitHub Actions

If you see `Error: google-github-actions/auth failed`, check:
1. Secrets are correctly set in GitHub (WIF_PROVIDER and WIF_SERVICE_ACCOUNT)
2. The repository name matches exactly (case-sensitive)
3. The Workload Identity Pool and Provider are created successfully

### Permission Denied

If Terraform operations fail with permission errors:
1. Verify the service account has the necessary roles
2. Add additional roles to the `terraform_roles` variable
3. Run `terraform apply` again to update IAM bindings

## References

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)
