# Managing Architecture Patterns

This guide explains how to add, remove, or modify architecture patterns in the repository.

## Centralized Pattern Configuration

All architecture patterns are defined in a **single location**:

```
.github/workflows/_patterns-config.yml
```

This reusable workflow serves as the single source of truth for all CI/CD workflows.

## Pattern Definitions

### All Patterns
The complete list of architecture patterns in the repository:

```yaml
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch"]'
```

This list is used by:
- `terraform-ci.yml` - Tests all patterns
- `terraform-plan-pr.yml` - Plans all patterns
- `terraform-apply.yml` - Deploys all patterns (when auto-apply is enabled)

### Production Patterns
A subset of patterns that are approved for production deployment:

```yaml
PROD_PATTERNS='["event-driven"]'
```

This list is used by:
- `terraform-apply-with-approval.yml` - Only deploys approved patterns to production

## Adding a New Architecture Pattern

To add a new architecture pattern to the repository:

### 1. Create the Architecture Directory Structure

```bash
mkdir -p architectures/new-pattern/gcp/{modules,environments/{dev,prod}}
```

### 2. Implement the Terraform Code

Follow the module conventions documented in `.claude/rules/04-module-conventions.md`:
- Create modules in `modules/`
- Create environment configs in `environments/{dev,prod}/`
- Follow naming conventions (snake_case)
- Add proper documentation

### 3. Update Pattern Configuration

Edit `.github/workflows/_patterns-config.yml`:

```yaml
# Add your new pattern to ALL_PATTERNS
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch", "new-pattern"]'

# Optionally add to PROD_PATTERNS if ready for production
PROD_PATTERNS='["event-driven", "new-pattern"]'
```

### 4. Update Workflow Manual Dispatch (Optional)

If you want the pattern available in manual workflow triggers, edit:

`.github/workflows/terraform-apply.yml`:
```yaml
workflow_dispatch:
  inputs:
    architecture:
      options:
        - event-driven
        - microservices-gke
        - workflow-batch
        - new-pattern  # Add here
```

### 5. Test the Pattern

The CI/CD workflows will automatically:
- Run format checks and validation
- Execute TFLint
- Perform security scanning
- Generate Terraform plans on PRs

## Removing an Architecture Pattern

To remove an existing pattern:

### 1. Remove from Pattern Configuration

Edit `.github/workflows/_patterns-config.yml`:

```yaml
# Remove the pattern from both lists
ALL_PATTERNS='["event-driven", "microservices-gke"]'
PROD_PATTERNS='["event-driven"]'
```

### 2. Remove from Manual Workflow (if present)

Edit `.github/workflows/terraform-apply.yml` and remove from options.

### 3. Archive or Delete the Directory

```bash
# Option 1: Keep for reference but remove from git tracking
git rm -r --cached architectures/old-pattern/

# Option 2: Delete completely
git rm -r architectures/old-pattern/
```

### 4. Destroy Cloud Resources (if deployed)

Before removing the pattern, destroy any deployed infrastructure:

```bash
cd architectures/old-pattern/gcp/environments/dev
terraform destroy

cd ../prod
terraform destroy
```

## Enabling/Disabling Production Deployment

To control which patterns can be deployed to production:

### Enable Production Deployment

Add the pattern to `PROD_PATTERNS` in `_patterns-config.yml`:

```yaml
PROD_PATTERNS='["event-driven", "microservices-gke"]'
```

### Disable Production Deployment

Remove the pattern from `PROD_PATTERNS`:

```yaml
# Only event-driven can be deployed to prod
PROD_PATTERNS='["event-driven"]'
```

This affects:
- `terraform-apply-with-approval.yml` - Will skip patterns not in the list
- Production environment protection rules still apply

## Benefits of Centralized Configuration

### Before (Scattered Definitions)
- Patterns defined in 4+ workflow files
- Risk of inconsistency between workflows
- Error-prone maintenance (easy to miss one file)

### After (Centralized)
- Single source of truth in `_patterns-config.yml`
- All workflows automatically synchronized
- Easy to add/remove patterns (edit one file)
- Clear separation between all patterns and prod-approved patterns

## Workflow Outputs

The `_patterns-config.yml` workflow provides three outputs:

| Output | Type | Description | Example |
|--------|------|-------------|---------|
| `all_patterns` | JSON array | All patterns for matrix strategy | `["event-driven", "microservices-gke", "workflow-batch"]` |
| `all_patterns_list` | String | Comma-separated for display | `event-driven,microservices-gke,workflow-batch` |
| `prod_patterns` | JSON array | Production-approved patterns | `["event-driven"]` |

## Example: Adding a "Serverless API" Pattern

Complete example of adding a new pattern:

```bash
# 1. Create structure
mkdir -p architectures/serverless-api/gcp/{modules,environments/{dev,prod}}

# 2. Implement Terraform code (modules and environments)
# ... (create your Terraform files)

# 3. Update _patterns-config.yml
# Edit the file to add "serverless-api" to ALL_PATTERNS

# 4. Update manual workflow options (optional)
# Edit terraform-apply.yml to add to workflow_dispatch options

# 5. Commit and push
git add architectures/serverless-api/
git add .github/workflows/_patterns-config.yml
git commit -m "feat: add serverless-api architecture pattern"
git push
```

The CI/CD pipeline will automatically test your new pattern on the next PR.

## Troubleshooting

### Pattern Not Running in CI

Check that:
1. Pattern is listed in `ALL_PATTERNS` in `_patterns-config.yml`
2. Pattern directory exists at `architectures/<pattern>/gcp/`
3. Workflow syntax is valid (GitHub Actions will show errors)

### Pattern Not Available for Manual Deployment

Check that:
1. Pattern is in `workflow_dispatch.inputs.architecture.options` in `terraform-apply.yml`
2. Pattern is in `ALL_PATTERNS` (for dev/prod) or `PROD_PATTERNS` (for prod-only)

### Production Deployment Not Working

Check that:
1. Pattern is listed in `PROD_PATTERNS` in `_patterns-config.yml`
2. Production environment protection rules are configured in GitHub
3. Required approvers are set for the production environment
