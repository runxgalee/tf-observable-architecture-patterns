# Development Workflow

## Working with Terraform

### Initialize and Plan

```bash
# Navigate to architecture pattern
cd architectures/<pattern>/gcp

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
cp secrets.auto.tfvars.example secrets.auto.tfvars
cp backend.hcl.example backend.hcl
# Edit files with your values

# Initialize with backend config
terraform init -backend-config=backend.hcl

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Format and Validate

```bash
# Format all Terraform files recursively
terraform fmt -recursive

# Check formatting without making changes
terraform fmt -check -recursive

# Validate configuration
cd architectures/<pattern>/gcp
terraform init -backend=false
terraform validate
```

### TFLint

```bash
# Run from pattern root
cd architectures/<pattern>/gcp

# Initialize TFLint
tflint --init

# Lint root configuration
tflint --format compact

# Lint modules
cd modules
for module in */; do
  echo "Linting module: $module"
  cd "$module"
  tflint --format compact
  cd ..
done
```

### Terraform Test

Native Terraform tests are located in `tests/`:

```bash
cd architectures/<pattern>/gcp

# Initialize (required for tests)
terraform init -backend=false

# Run all unit tests
terraform test -test-directory=tests

# Run specific test file
terraform test -test-directory=tests -filter=pubsub.tftest.hcl
```

## Backend Configuration

This repository uses **partial backend configuration** for security:
- `backend.tf` - Committed (no sensitive values)
- `backend.hcl` - Contains actual bucket names (git-ignored)
- `secrets.auto.tfvars` - Contains sensitive variables (git-ignored)

### Local Setup

Create `backend.hcl` from example:
```hcl
bucket = "your-terraform-state-bucket"
prefix = "terraform/<pattern>/state"
```

Create `secrets.auto.tfvars` from example for sensitive values (API keys, tokens, etc.).

See `docs/backend-setup.md` for complete setup instructions.

## Bootstrap Resources

Before deploying architectures, set up bootstrap resources in order:

### 1. Terraform State Bucket (`bootstrap/gcp/terraform-state/`)
- Creates GCS bucket for remote state
- Enables versioning and encryption
- Uses local state (bootstrap only)

### 2. Secret Manager (`bootstrap/gcp/secrets/`)
- Creates secrets for CI/CD (state bucket names)
- Grants access to GitHub Actions service account

### 3. GitHub Actions Authentication (`bootstrap/gcp/github-actions-auth/`)
- Sets up Workload Identity Federation
- No service account keys required
- Grants Secret Manager access

## Terraform Version

- Required: `>= 1.13`
- CI uses: `1.13.0`

Specified in each module's `versions.tf`.

## Environment Management

Environment-specific configuration uses `.auto.tfvars` files:
- `dev.auto.tfvars` - Dev environment settings (committed)
- `secrets.auto.tfvars` - Sensitive values (git-ignored)

The `environment` variable controls resource naming prefix.
