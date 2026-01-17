---
paths: .github/workflows/*.yml
---

# CI/CD Workflows

## Workflow Files

### _patterns-config.yml
**Centralized configuration** (reusable workflow):
- Defines all architecture patterns in one place
- Single source of truth for pattern management
- Called by all other workflows to get pattern lists
- Outputs:
  - `all_patterns`: All patterns as JSON array
  - `all_patterns_list`: All patterns as comma-separated list
  - `prod_patterns`: Production-enabled patterns as JSON array

To add or remove architecture patterns, edit this file only.

### terraform-ci.yml
Runs on PRs and main branch:
- Format check (`terraform fmt -check`)
- Validation (`terraform validate`)
- TFLint (modules and root)
- Terraform Test (`terraform test` for `tests/*.tftest.hcl`)
- Security scanning with Trivy
- Documentation checks
- Tests all patterns from `_patterns-config.yml`

### terraform-plan-pr.yml
Posts plan output to PRs for review before merge.
- Plans all patterns from `_patterns-config.yml`

### terraform-apply-with-approval.yml (Recommended)
Deployment workflow with safety:
- Auto-applies to dev
- Requires manual approval for prod
- Uses `prod_patterns` from `_patterns-config.yml`

### terraform-apply.yml
Auto-deployment (less safe):
- Auto-applies to both dev and prod
- Uses `all_patterns` from `_patterns-config.yml`

## Change Detection

Workflows automatically detect which architecture patterns changed:
- Analyzes git diff to find modified patterns
- Only runs jobs for changed architectures
- Tests all patterns if workflow files change

The detection logic:
```bash
# For PRs
git diff --name-only origin/${{ github.base_ref }}...HEAD

# For main branch pushes
git diff --name-only HEAD~1 HEAD

# Extract changed patterns
grep '^architectures/' | cut -d'/' -f2 | sort -u
```

## Secret Management

### GitHub Secrets

Configure in repository **Settings → Secrets and variables → Actions**:

- `WIF_PROVIDER`: Workload Identity Provider full path (required for authentication)
  - Format: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
- `WIF_SERVICE_ACCOUNT`: Service account email for GitHub Actions (required for authentication)
  - Format: `github-actions-terraform@PROJECT_ID.iam.gserviceaccount.com`
- `GCP_PROJECT_ID`: GCP Project ID (required for Secret Manager access)
  - Format: `your-gcp-project-id`

### GCP Secret Manager

Environment-specific secrets are managed in GCP Secret Manager for improved security and auditability:

- `github-actions-dev-tf-state-bucket`: Terraform state bucket for dev environment
- `github-actions-prod-tf-state-bucket`: Terraform state bucket for prod environment

Workflows automatically fetch these secrets after authentication using the `google-github-actions/get-secretmanager-secrets@v3` action.

**Setup**: See `bootstrap/gcp/secrets/README.md` for Secret Manager configuration.

See `docs/gitops-setup.md` for complete setup instructions.

## CI Environment Variables

- `TF_VERSION`: Terraform version used in CI (currently `1.13.0`)
