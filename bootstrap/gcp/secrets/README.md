# Centralized Secrets Management with Secret Manager

This Terraform module provides centralized secrets management for the entire repository, including GitHub Actions, architecture patterns, and monitoring systems. It creates Secret Manager secret containers with flexible configuration and IAM-based access control.

**Important**: This module creates **empty secret containers only**. Secret data (actual values) must be populated manually outside of Terraform using `gcloud` CLI or the Cloud Console. This follows security best practices by keeping sensitive data out of Terraform state.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Secret Manager                        │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ GitHub Actions   │  │  Monitoring      │                │
│  │ Category         │  │  Category        │                │
│  ├──────────────────┤  ├──────────────────┤                │
│  │ dev-wif-sa       │  │ dev-slack-webhook│                │
│  │ prod-wif-sa      │  │ prod-slack-...   │                │
│  │ dev-tf-bucket    │  │ dev-pagerduty... │                │
│  │ prod-tf-bucket   │  │ prod-pagerduty...│                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Architecture     │  │  Custom          │                │
│  │ Category         │  │  Category        │                │
│  ├──────────────────┤  ├──────────────────┤                │
│  │ event-driven-... │  │ ...              │                │
│  │ microservices-...│  │ ...              │                │
│  │ workflow-batch...│  │ ...              │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         ▲                    ▲                    ▲
         │                    │                    │
    ┌────┴────┐          ┌────┴────┐         ┌────┴────┐
    │ GitHub  │          │ Cloud   │         │ GKE     │
    │ Actions │          │ Run     │         │ Pods    │
    └─────────┘          └─────────┘         └─────────┘
```

## Features

- **Flexible Secret Categories**: GitHub Actions, monitoring, architecture-specific, custom
- **Environment Isolation**: Separate secrets for dev and prod
- **Granular IAM Control**: Per-secret service account access configuration
- **Audit Logging**: All secret access logged in Cloud Audit Logs
- **Terraform-Managed Infrastructure**: Secret containers managed by Terraform, data managed manually
- **Centralized Management**: Single source of truth for all project secrets

## Secret Categories

### 1. GitHub Actions (`github-actions`)
Secrets used by GitHub Actions workflows for authentication and CI/CD operations.

**Naming**: `github-actions-{env}-{name}`

**Examples**:
- `github-actions-dev-wif-service-account`: WIF service account email for dev
- `github-actions-prod-tf-state-bucket`: Terraform state bucket for prod

### 2. Monitoring (`monitoring`)
Secrets for alerting and monitoring integrations.

**Naming**: `monitoring-{env}-{name}`

**Examples**:
- `monitoring-dev-slack-webhook-url`: Slack webhook for dev alerts
- `monitoring-prod-pagerduty-integration-key`: PagerDuty key for prod

### 3. Architecture (`architecture`)
Secrets specific to architecture patterns.

**Current patterns**:
- `event-driven` (implemented)

**Future patterns**:
- `microservices-gke` (planned)
- `workflow-batch` (planned)

**Naming**: `{pattern}-{env}-{name}`

**Examples**:
- `event-driven-dev-api-key`: API key for event-driven pattern in dev
- `microservices-prod-database-url`: Database connection for microservices in prod (future)

### 4. Custom Categories
You can define custom categories for project-specific needs.

**Naming**: `{category}-{env}-{name}`

## Why Secret Data is Not in Terraform

This module intentionally does NOT manage secret values in Terraform for these reasons:

1. **Security**: Keeps sensitive values out of Terraform state files
2. **Access Control**: Terraform state readers don't automatically get access to secret values
3. **Audit Trail**: Secret value changes are logged via Cloud Audit Logs, not hidden in Terraform
4. **Secret Rotation**: Update secrets without running Terraform
5. **Best Practice**: Follows principle of separating infrastructure from secrets management

## Prerequisites

1. **Secret Manager API**: Must be enabled in your GCP project
2. **Service Accounts**: Service accounts that need secret access must already exist
3. **IAM Permissions**: Terraform service account needs `roles/secretmanager.admin`

## Usage

### 1. Copy and Configure Variables

```bash
cd bootstrap/gcp/secrets
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration (see examples below).

### 2. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 3. Populate Secret Data

After Terraform creates the secret containers, populate them with actual values:

```bash
# GitHub Actions secrets
echo -n "github-actions-terraform@project.iam.gserviceaccount.com" | \
  gcloud secrets versions add github-actions-dev-wif-service-account \
  --project=your-project-id \
  --data-file=-

# Monitoring secrets
echo -n "https://hooks.slack.com/services/..." | \
  gcloud secrets versions add monitoring-dev-slack-webhook-url \
  --project=your-project-id \
  --data-file=-

# Architecture secrets
echo -n "your-api-key-value" | \
  gcloud secrets versions add event-driven-dev-api-key \
  --project=your-project-id \
  --data-file=-
```

### 4. Verify Secrets

```bash
# List all secrets
gcloud secrets list --project=your-project-id

# List secrets by category
gcloud secrets list --project=your-project-id --filter="labels.category=github-actions"

# View secret value (requires secretAccessor role)
gcloud secrets versions access latest --secret="github-actions-dev-wif-service-account"
```

## Configuration Examples

### Minimal Configuration (GitHub Actions Only)

```hcl
project_id = "your-gcp-project-id"

secrets = {
  "wif-service-account" = {
    environments     = ["dev", "prod"]
    category         = "github-actions"
    description      = "GitHub Actions WIF service account email"
    service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
  }

  "tf-state-bucket" = {
    environments     = ["dev", "prod"]
    category         = "github-actions"
    description      = "Terraform state bucket name"
    service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
  }
}
```

### Comprehensive Configuration (All Categories)

```hcl
project_id = "your-gcp-project-id"

secrets = {
  # GitHub Actions
  "wif-service-account" = {
    environments     = ["dev", "prod"]
    category         = "github-actions"
    description      = "GitHub Actions WIF service account email"
    service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
  }

  "tf-state-bucket" = {
    environments     = ["dev", "prod"]
    category         = "github-actions"
    description      = "Terraform state bucket name"
    service_accounts = ["github-actions-terraform@project.iam.gserviceaccount.com"]
  }

  # Monitoring
  "slack-webhook-url" = {
    environments = ["dev", "prod"]
    category     = "monitoring"
    description  = "Slack webhook URL for alert notifications"
    service_accounts = [
      "dev-event-driven-cloudrun@project.iam.gserviceaccount.com",
      "prod-event-driven-cloudrun@project.iam.gserviceaccount.com"
    ]
  }

  "pagerduty-integration-key" = {
    environments     = ["prod"]  # Only prod needs PagerDuty
    category         = "monitoring"
    description      = "PagerDuty integration key for critical alerts"
    service_accounts = ["prod-event-driven-cloudrun@project.iam.gserviceaccount.com"]
  }

  # Architecture: Event-Driven (implemented)
  "event-driven-api-key" = {
    environments = ["dev", "prod"]
    category     = "architecture"
    description  = "API key for event-driven pattern external service"
    service_accounts = [
      "dev-event-driven-cloudrun@project.iam.gserviceaccount.com",
      "prod-event-driven-cloudrun@project.iam.gserviceaccount.com"
    ]
  }

  # Architecture: Microservices GKE (future pattern)
  # "microservices-database-url" = {
  #   environments = ["dev", "prod"]
  #   category     = "architecture"
  #   description  = "Database connection string for microservices"
  #   service_accounts = [
  #     "dev-microservices-api@project.iam.gserviceaccount.com",
  #     "prod-microservices-api@project.iam.gserviceaccount.com"
  #   ]
  # }
}

additional_labels = {
  team = "platform"
  cost_center = "engineering"
}
```

## Using Secrets in GitHub Actions

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: $${{ secrets.WIF_PROVIDER }}
    service_account: $${{ secrets.WIF_SERVICE_ACCOUNT }}

- name: Get secrets from Secret Manager
  id: secrets
  uses: google-github-actions/get-secretmanager-secrets@v3
  with:
    secrets: |-
      wif_service_account:projects/$${{ env.GCP_PROJECT_ID }}/secrets/github-actions-$${{ matrix.environment }}-wif-service-account
      tf_state_bucket:projects/$${{ env.GCP_PROJECT_ID }}/secrets/github-actions-$${{ matrix.environment }}-tf-state-bucket

- name: Use secrets in Terraform
  run: |
    terraform init \
      -backend-config="bucket=$${{ steps.secrets.outputs.tf_state_bucket }}"
```

## Using Secrets in Cloud Run

```hcl
# In your Terraform configuration
resource "google_cloud_run_v2_service" "app" {
  # ...

  template {
    service_account = google_service_account.app.email

    containers {
      # ...

      env {
        name = "SLACK_WEBHOOK_URL"
        value_source {
          secret_key_ref {
            secret  = "monitoring-dev-slack-webhook-url"
            version = "latest"
          }
        }
      }

      env {
        name = "API_KEY"
        value_source {
          secret_key_ref {
            secret  = "event-driven-dev-api-key"
            version = "latest"
          }
        }
      }
    }
  }
}
```

## Using Secrets in GKE (Future Pattern)

**Note**: This is for the planned `microservices-gke` pattern.

```yaml
# Kubernetes manifest
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: microservices-api
  containers:
  - name: app
    image: gcr.io/project/app:latest
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: url
---
# Secret with data from Secret Manager (via External Secrets Operator)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcpsm-secret-store
    kind: SecretStore
  target:
    name: database-credentials
  data:
  - secretKey: url
    remoteRef:
      key: microservices-dev-database-url
```

## Manual Secret Management

### Update Secret Value

```bash
# Add new version
echo -n "new-value" | gcloud secrets versions add SECRET_ID \
  --project=your-project-id \
  --data-file=-

# Disable old version
gcloud secrets versions disable VERSION_NUMBER --secret=SECRET_ID
```

### Grant Access to Additional Service Accounts

```bash
gcloud secrets add-iam-policy-binding SECRET_ID \
  --member="serviceAccount:another-sa@project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Rotate Secrets

```bash
# 1. Add new secret version
echo -n "new-secret-value" | gcloud secrets versions add SECRET_ID --data-file=-

# 2. Test applications with new version

# 3. Disable old version
gcloud secrets versions disable OLD_VERSION --secret=SECRET_ID

# 4. (Optional) Destroy old version after retention period
gcloud secrets versions destroy OLD_VERSION --secret=SECRET_ID
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant `secretAccessor` role, never `secretAdmin`
2. **Regular Rotation**: Rotate secrets regularly (especially API keys and credentials)
3. **Audit Logging**: Review Cloud Audit Logs for suspicious secret access patterns
4. **Environment Separation**: Use different secret values for dev and prod
5. **Version Control**: Keep old versions for rollback capability
6. **Access Review**: Periodically review service account access to secrets

## Outputs

This module provides several useful outputs:

### `secret_ids`
Map of all created secrets (key = secret_id)

### `secret_full_names`
Map of all secrets with their full resource names (for use in GitHub Actions)

### `secrets_by_category`
Secrets grouped by category for easy reference

### `secrets_by_environment`
Secrets grouped by environment for easy reference

## Troubleshooting

### "Permission denied" when accessing secrets

```bash
# Check secret IAM policy
gcloud secrets get-iam-policy SECRET_ID

# Verify service account has secretAccessor role
gcloud secrets get-iam-policy SECRET_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/secretmanager.secretAccessor"
```

### Secret not found

Ensure:
1. Secret name matches the naming convention: `{category}-{env}-{name}`
2. Secret was created successfully: `terraform output secret_ids`
3. Workload Identity/service account authentication succeeded

### IAM propagation delay

After applying Terraform, IAM changes may take up to 2 minutes to propagate. If you encounter permission errors immediately after `terraform apply`, wait a few minutes and retry.

## Cost Considerations

- **Secret storage**: $0.06 per secret per month
- **Secret access**: $0.03 per 10,000 accesses
- **Typical cost for this setup**:
  - 10 secrets: ~$0.60/month storage
  - 100,000 accesses/month: ~$0.30/month access
  - **Total: ~$1/month**

## Migration from GitHub Secrets

1. ✅ Apply this Terraform module to create secret containers
2. ✅ Populate secret values using `gcloud` CLI
3. ✅ Update one GitHub Actions workflow to test Secret Manager integration
4. ✅ Validate the workflow runs successfully
5. ✅ Update remaining workflows
6. ⚠️ Keep `WIF_PROVIDER` in GitHub Secrets (required for bootstrap)
7. ✅ Remove other secrets from GitHub Secrets after migration

## Next Steps

After setting up Secret Manager:

1. **Populate Secret Values**:
   - Use `gcloud secrets versions add` to add actual secret values
   - See "Populate Secret Data" section above

2. **Update GitHub Actions Workflows**:
   - Use `google-github-actions/get-secretmanager-secrets` to retrieve secrets
   - Replace GitHub Secrets references with Secret Manager
   - See `.github/workflows/` for examples

3. **Configure Architecture Patterns**:
   - Reference secrets in Terraform configurations
   - Use Cloud Run secret mounting or environment variables
   - See architecture pattern READMEs for examples

## References

- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [GitHub Actions get-secretmanager-secrets](https://github.com/google-github-actions/get-secretmanager-secrets)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)
