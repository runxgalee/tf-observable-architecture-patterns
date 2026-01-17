# Security and Testing

## Security Best Practices

### 1. State Management
- Remote state in GCS with versioning enabled
- State file encryption at rest
- Separate state files per environment

### 2. Secrets Management
- Use Secret Manager for all sensitive data
- Never commit secrets to code or `terraform.tfvars`
- Use `secrets.auto.tfvars` for local development (git-ignored)
- CI/CD retrieves secrets from Secret Manager

### 3. Service Accounts
- Minimum required permissions per component
- Separate service accounts for different services
- Document required roles in IAM configuration

### 4. Workload Identity
- Use Workload Identity Federation for CI/CD (no service account keys)
- GitHub Actions authenticates via OIDC
- No static credentials in pipelines

### 5. Private Resources
- VPC connectors for Cloud Run/Cloud Functions
- Restrict public access to load balancers only

## Testing and Validation

### Before Committing

Run these commands locally:

```bash
# Navigate to pattern
cd architectures/<pattern>/gcp

# Format code
terraform fmt -recursive

# Validate syntax
terraform init -backend=false
terraform validate

# Run TFLint
tflint --init
tflint

# Run Terraform tests
terraform test -test-directory=tests
```

### Terraform Native Tests

Tests are located in `tests/` using `.tftest.hcl` files:

```bash
# Run all tests
terraform test -test-directory=tests

# Run specific test
terraform test -test-directory=tests -filter=pubsub.tftest.hcl

# Verbose output
terraform test -test-directory=tests -verbose
```

Test files cover:
- Variable validation
- Resource creation
- Output values
- Module integration

### CI Pipeline Checks

The CI pipeline automatically runs:
- **Format check**: `terraform fmt -check -recursive`
- **Validation**: `terraform validate`
- **TFLint**: Code quality and best practices (modules + root)
- **Terraform Test**: Native test framework (`tests/*.tftest.hcl`)
- **Trivy**: Security scanning for misconfigurations
- **Documentation**: Verifies required files exist

### Security Scanning

Trivy scans for:
- Hardcoded secrets
- Insecure resource configurations
- Missing security controls
- Compliance violations

All security issues should be fixed before merging.

## Validation Script

Use the validation script to check a pattern:

```bash
./scripts/validate-tf.sh event-driven
```

This runs format check, validation, TFLint, and tests in one command.
