# CI/CD Workflow Summary

## Overview

This repository uses four GitHub Actions workflows to implement a complete CI/CD pipeline for Terraform infrastructure. All workflows use hardcoded architecture patterns for simplicity and predictability.

## Architecture Patterns

Three architecture patterns are defined across all workflows:
- `event-driven`: Pub/Sub + Cloud Run event-driven architecture
- `microservices-gke`: GKE Autopilot microservices platform
- `workflow-batch`: Cloud Scheduler + Workflows + Cloud Run Jobs

## Workflow Files

### 1. terraform-ci.yml - Continuous Integration

**Purpose**: Comprehensive validation and security scanning for all Terraform code

**Triggers**:
- Pull requests to main
- Pushes to main
- Changes in `architectures/**` or `.github/workflows/terraform-*.yml`

**Jobs** (all run in parallel):
- `terraform-format`: Format validation (3 jobs - one per pattern)
- `terraform-validate`: Syntax validation (6 jobs - 3 patterns × 2 environments)
- `tflint`: Linting with TFLint (3 jobs)
- `terraform-docs`: Documentation checks (3 jobs)
- `security-scan`: Trivy security scanning (3 jobs)
- `test-terraform-syntax`: Module syntax testing (3 jobs)
- `ci-summary`: Aggregated results summary

**Total**: 21 parallel jobs

**Enforcement**: CI must pass before PRs can be merged

---

### 2. terraform-plan-pr.yml - Pull Request Planning

**Purpose**: Generate Terraform plans for review before merging

**Triggers**:
- Pull requests to main
- Changes in `architectures/**`

**Jobs**:
- `terraform-plan`: Run `terraform plan` for all patterns and environments (6 jobs)
  - 3 patterns × 2 environments (dev, prod)
  - Posts plan output as PR comment for review

**Total**: 6 parallel jobs

**Features**:
- Plan summaries with resource counts
- Inline PR comments for easy review
- No actual infrastructure changes

---

### 3. terraform-apply.yml - Auto-Deploy to Dev

**Purpose**: Automatically deploy changes to dev environment when merged to main

**Triggers**:
- Push to main branch
- Changes in `architectures/**`
- Manual workflow_dispatch (for selective deploys)

**Jobs**:
- `prepare-matrix`: Prepare deployment matrix based on trigger type
- `terraform-apply`: Apply changes (3 jobs for auto-deploy, variable for manual)
  - Auto-deploy: All 3 patterns to dev
  - Manual: Selected pattern(s) to selected environment

**Total**: 3 jobs for auto-deploy (all patterns × dev)

**Manual Options**:
- Architecture: event-driven, microservices-gke, workflow-batch, or all
- Environment: dev or prod

---

### 4. terraform-apply-with-approval.yml - Production Deployment

**Purpose**: Deploy to production with manual approval gate

**Triggers**:
- Push to main branch
- Changes in `architectures/**`

**Jobs**:
- `terraform-apply-prod`: Apply to production (3 jobs - one per pattern)
- `summary`: Deployment summary

**Total**: 3 jobs (all patterns × prod)

**Protection**: Requires manual approval through GitHub environment protection rules

**Workflow**:
1. Changes merged to main
2. Workflow triggers and waits for approval
3. Reviewer examines plan and approves/rejects
4. On approval, deploys all patterns to production

---

## Deployment Flow

```
┌─────────────────┐
│   Pull Request  │
└────────┬────────┘
         │
         ├─► terraform-ci.yml (validate, lint, scan)
         │   └─► 21 parallel checks
         │
         └─► terraform-plan-pr.yml (plan dev & prod)
             └─► 6 plans posted as comments
                 │
                 ▼
         ┌───────────────┐
         │  Merge to Main │
         └───────┬────────┘
                 │
                 ├─► terraform-ci.yml (re-validate on main)
                 │
                 ├─► terraform-apply.yml (auto-deploy)
                 │   └─► Apply 3 patterns to dev
                 │
                 └─► terraform-apply-with-approval.yml
                     └─► Wait for approval
                         │
                         ▼
                     ┌──────────────┐
                     │ Manual Review │
                     └──────┬────────┘
                            │
                            └─► Apply 3 patterns to prod
```

## Job Parallelization

All workflows use GitHub Actions matrix strategy for parallelization:

| Workflow | Jobs | Patterns | Environments | Total |
|----------|------|----------|--------------|-------|
| terraform-ci.yml | 6 types | 3 | varies | 21 |
| terraform-plan-pr.yml | 1 | 3 | 2 | 6 |
| terraform-apply.yml | 1 | 3 | 1 (dev) | 3 |
| terraform-apply-with-approval.yml | 1 | 3 | 1 (prod) | 3 |

## Environment Strategy

| Environment | Trigger | Approval | Purpose |
|-------------|---------|----------|---------|
| dev | Auto on merge | No | Rapid iteration, testing |
| prod | Auto on merge | **Yes** | Production workloads |

## Required Secrets

All workflows require these GitHub secrets:

### Authentication
- `WIF_PROVIDER`: Workload Identity Federation provider
- `WIF_SERVICE_ACCOUNT`: GCP service account for GitHub Actions
- `GCP_PROJECT_ID`: GCP project ID for Secret Manager access

### State Management (stored in GCP Secret Manager)
- `github-actions-dev-tf-state-bucket`: Dev Terraform state bucket
- `github-actions-prod-tf-state-bucket`: Prod Terraform state bucket

Secrets are automatically fetched from GCP Secret Manager during workflow execution.

## Adding New Architecture Patterns

To add a new pattern (e.g., `serverless-api`):

1. Create directory structure: `architectures/serverless-api/gcp/`

2. Update all four workflow files:
   - `.github/workflows/terraform-ci.yml`
   - `.github/workflows/terraform-plan-pr.yml`
   - `.github/workflows/terraform-apply.yml`
   - `.github/workflows/terraform-apply-with-approval.yml`

3. In each file, update:
   ```yaml
   env:
     ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch", "serverless-api"]'
   
   jobs:
     <job-name>:
       strategy:
         matrix:
           pattern:
             - event-driven
             - microservices-gke
             - workflow-batch
             - serverless-api
   ```

4. Update `terraform-apply.yml` workflow_dispatch options:
   ```yaml
   workflow_dispatch:
     inputs:
       architecture:
         options:
           - event-driven
           - microservices-gke
           - workflow-batch
           - serverless-api
           - all
   ```

## Best Practices

1. **Always create PRs**: Never push directly to main
2. **Review plans carefully**: Check terraform-plan-pr.yml output in PR comments
3. **Monitor CI**: Ensure all 21 CI checks pass before merging
4. **Dev first**: Changes automatically deploy to dev for validation
5. **Approve production**: Review and approve prod deployments within 30 days
6. **Use manual dispatch**: For hotfixes or selective deployments
7. **Check status**: Monitor workflow runs in GitHub Actions tab

## Troubleshooting

### Workflow not triggering
- Verify changes are in `architectures/**` path
- Check workflow trigger configuration
- Ensure branch is main (for deploy workflows)

### Authentication failures
- Verify WIF secrets are configured correctly
- Check service account permissions in GCP
- Ensure Secret Manager secrets exist

### Plan failures
- Check Terraform syntax with `terraform validate`
- Run `terraform fmt -recursive` locally
- Review TFLint warnings

### Apply failures
- Review plan output before applying
- Check for resource quota limits in GCP
- Verify backend configuration is correct

## Migration Notes

These workflows were migrated from dynamic change detection to hardcoded patterns on 2026-01-09. See `docs/hardcoded-patterns-migration.md` for details.

**Key changes**:
- Removed 240+ lines of bash scripting
- Simplified matrix configuration
- More predictable behavior
- Easier to maintain and extend
