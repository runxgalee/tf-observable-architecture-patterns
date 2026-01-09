# Migration to Hardcoded Architecture Patterns

## Overview

This document describes the migration from dynamic change detection to hardcoded architecture pattern definitions in all CI/CD workflows. This change affects all four workflow files and removes ~240 lines of complex bash scripting.

## Changes Made

All four CI/CD workflows have been updated to use hardcoded architecture patterns instead of dynamic change detection.

### 1. terraform-plan-pr.yml (PR Planning)

**Before:**
- Used `detect-changes` job to scan git diff for changed files
- Dynamically determined which architecture patterns to run
- Only ran for patterns with detected changes

**After:**
- Removed `detect-changes` job entirely
- Hardcoded architecture patterns in environment variable and matrix
- Always runs for all three patterns: `event-driven`, `microservices-gke`, `workflow-batch`
- Simplified workflow structure

**Key Changes:**
```yaml
env:
  TF_VERSION: '1.13.0'
  # Hardcoded architecture patterns
  ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch"]'

jobs:
  terraform-plan:
    strategy:
      matrix:
        pattern:
          - event-driven
          - microservices-gke
          - workflow-batch
        environment: [dev, prod]
```

### 2. terraform-apply.yml (Auto-Deploy to Dev)

**Before:**
- Used `detect-changes` job with complex logic for:
  - workflow_run trigger (checking git diff)
  - workflow_dispatch (manual selection)
- Auto-detected changed architectures from commits
- Different behavior based on trigger type

**After:**
- Replaced `detect-changes` with simpler `prepare-matrix` job
- Changed trigger from `workflow_run` to direct `push` on main branch
- Hardcoded architecture patterns in environment variable
- Simplified logic:
  - Push events: Apply all patterns to dev environment
  - Manual dispatch: User selects specific pattern/environment
- Maintained workflow_dispatch functionality for manual deploys

**Key Changes:**
```yaml
env:
  TF_VERSION: '1.13.0'
  # Hardcoded architecture patterns
  ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch"]'

jobs:
  prepare-matrix:
    # Simple matrix preparation without git diff scanning
    # Uses hardcoded patterns for auto-deploys
    # Respects manual selection for workflow_dispatch
```

### 3. terraform-apply-with-approval.yml (Prod Deployment with Approval)

**Before:**
- Used `detect-changes` job to scan git diff for changed files
- Only deployed changed patterns to production
- Complex bash logic to extract pattern names from commits

**After:**
- Removed `detect-changes` job entirely
- Hardcoded architecture patterns in matrix
- Always deploys all three patterns to production (with approval)
- Requires manual approval via GitHub environment protection rules

**Key Changes:**
```yaml
env:
  TF_VERSION: '1.13.0'
  # Hardcoded architecture patterns
  ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch"]'

jobs:
  terraform-apply-prod:
    environment:
      name: production  # Requires manual approval
    strategy:
      matrix:
        pattern:
          - event-driven
          - microservices-gke
          - workflow-batch
```

### 4. terraform-ci.yml (CI Validation)

**Before:**
- Used `detect-changes` job to detect changed architectures
- Only ran checks for changed patterns
- Special logic for workflow file changes (test all patterns)
- Different behavior for PRs vs pushes to main

**After:**
- Removed `detect-changes` job entirely
- Hardcoded architecture patterns in all job matrices
- Always runs all checks for all patterns
- Consistent behavior across all event types
- Six separate jobs all use the same hardcoded pattern list

**Key Changes:**
```yaml
env:
  TF_VERSION: '1.13.0'
  # Hardcoded architecture patterns
  ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch"]'

jobs:
  terraform-format:
    strategy:
      matrix:
        pattern:
          - event-driven
          - microservices-gke
          - workflow-batch

  terraform-validate:
    strategy:
      matrix:
        pattern:
          - event-driven
          - microservices-gke
          - workflow-batch
        environment: [dev, prod]

  # Same pattern for: tflint, terraform-docs, security-scan, test-terraform-syntax
```

## Benefits

1. **Simplicity**: Removed ~240 lines of complex bash scripting for change detection across all workflows
2. **Predictability**: Always runs the same set of patterns, no surprises
3. **Maintainability**: Easy to add/remove patterns by updating the matrix
4. **Consistency**: Same patterns always tested/deployed together
5. **Clarity**: Clear at a glance which patterns are managed by CI/CD

## Trade-offs

1. **Performance**: Always runs all patterns even if only one changed
   - However, with 3 patterns × 2 environments = 6 parallel jobs, runtime is still reasonable
   - GitHub Actions provides sufficient parallelization
2. **CI Minutes**: May consume slightly more CI minutes
   - Benefit: More thorough testing and validation

## How to Add/Remove Patterns

To add a new architecture pattern, update all four workflow files:

1. **Update `ARCHITECTURE_PATTERNS` environment variable** in all four workflows:
   - `.github/workflows/terraform-plan-pr.yml`
   - `.github/workflows/terraform-apply.yml`
   - `.github/workflows/terraform-apply-with-approval.yml`
   - `.github/workflows/terraform-ci.yml`

   ```yaml
   ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch", "new-pattern"]'
   ```

2. **Add to the matrix definitions** in all four workflows:
   ```yaml
   matrix:
     pattern:
       - event-driven
       - microservices-gke
       - workflow-batch
       - new-pattern
   ```

3. **Update workflow_dispatch options** in `terraform-apply.yml`:
   ```yaml
   workflow_dispatch:
     inputs:
       architecture:
         options:
           - event-driven
           - microservices-gke
           - workflow-batch
           - new-pattern
           - all
   ```

To remove a pattern, simply remove it from all the locations above in all four workflow files.

## Workflow Behavior

### CI Validation (terraform-ci.yml)
- **Trigger**: PR or push to main with changes in `architectures/**` or `.github/workflows/terraform-*.yml`
- **Action**: Run all validation checks for all 3 patterns
  - Format check (3 jobs)
  - Validate for dev and prod (6 jobs)
  - TFLint (3 jobs)
  - Documentation check (3 jobs)
  - Security scan with Trivy (3 jobs)
  - Syntax test (3 jobs)
- **Output**: CI summary with status of all checks

### Pull Request Planning (terraform-plan-pr.yml)
- **Trigger**: PR to main with changes in `architectures/**`
- **Action**: Run `terraform plan` for all 3 patterns × 2 environments (6 jobs)
- **Output**: Plan summary posted as PR comment for each pattern/environment

### Auto-Deploy to Dev (terraform-apply.yml)
- **Trigger**: Push to main with changes in `architectures/**`
- **Action**: Run `terraform apply` for all 3 patterns × dev environment (3 jobs)
- **Output**: Deployment summary in workflow run

### Manual Deployment (terraform-apply.yml)
- **Trigger**: Manual workflow_dispatch from GitHub Actions UI
- **Input**: Select specific pattern (or "all") and environment (dev/prod)
- **Action**: Apply selected pattern(s) to selected environment
- **Use Case**: Production deployments, hotfixes, or selective rollouts

### Production Deployment (terraform-apply-with-approval.yml)
- **Trigger**: Push to main with changes in `architectures/**`
- **Action**: Run `terraform apply` for all 3 patterns to production (3 jobs)
- **Protection**: Requires manual approval via GitHub environment protection rules
- **Output**: Deployment summary in workflow run

## Testing the Changes

1. **Create a PR** modifying any file under `architectures/`
   - Verify terraform-ci.yml runs (21 total jobs across all checks)
   - Verify terraform-plan-pr.yml runs (6 plan jobs: 3 patterns × 2 environments)
   - Check PR comments for plan summaries

2. **Merge to main**
   - Verify terraform-ci.yml runs again on main branch
   - Verify terraform-apply.yml runs (3 apply jobs: all patterns × dev)
   - Verify terraform-apply-with-approval.yml triggers (waits for approval)
   - Check workflow summaries

3. **Approve production deployment**
   - Go to Actions → Terraform Apply (with Approval)
   - Review the waiting deployment and approve
   - Verify 3 prod apply jobs run (all patterns × prod)

4. **Manual dispatch**
   - Go to Actions → Terraform Apply on Main → Run workflow
   - Select a specific pattern and environment
   - Verify only selected jobs run

## Migration Notes

- No changes required to Terraform code or module structure
- No changes required to repository secrets or variables
- Workflows remain compatible with existing GCP authentication setup
- Environment protection rules still apply for prod deployments
