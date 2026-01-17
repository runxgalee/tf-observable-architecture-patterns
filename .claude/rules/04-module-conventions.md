# Module Structure and Conventions

## Architecture Pattern Structure

Each architecture pattern uses a flat root configuration with modular components:

```
architectures/<pattern>/gcp/
├── main.tf              # Module calls and orchestration
├── variables.tf         # Root input variables
├── outputs.tf           # Root outputs
├── providers.tf         # Provider configuration
├── versions.tf          # Terraform version constraints
├── backend.tf           # Backend configuration (partial)
├── *.auto.tfvars        # Environment-specific values
├── modules/             # Modular components
│   ├── cloudrun/
│   ├── iam_bindings/
│   ├── monitoring/
│   ├── observability/
│   ├── pubsub/
│   └── service_accounts/
└── tests/          # Terraform native tests
    └── *.tftest.hcl
```

## Module Structure

Each module follows this standard structure:

```
modules/<module-name>/
├── versions.tf          # Terraform and provider versions
├── main.tf              # Data sources and locals
├── <resource>.tf        # Primary resource file (e.g., pubsub.tf, cloudrun.tf)
├── variables.tf         # Input variables (with descriptions)
└── outputs.tf           # Output values (with descriptions)
```

## Module Types

| Module | Purpose |
|--------|---------|
| `service_accounts/` | Service account creation |
| `iam_bindings/` | IAM role bindings |
| `pubsub/` | Pub/Sub topics and subscriptions |
| `cloudrun/` | Cloud Run services |
| `monitoring/` | Alert policies and notification channels |
| `observability/` | Logging and dashboards |

## Version Requirements

### Terraform Version

**All modules MUST specify Terraform version >= 1.13**

Every `versions.tf` file must include:

```hcl
terraform {
  required_version = ">= 1.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"  # or appropriate version
    }
  }
}
```

This ensures:
- Consistent behavior across environments
- Support for modern Terraform features (including native tests)
- CI/CD pipeline compatibility (uses Terraform 1.13.0)

## Naming Conventions

These conventions are enforced by TFLint (`.tflint.hcl`):

- **Variables, locals, outputs**: `snake_case`
- **Resources**: `snake_case`
- **Resource prefixes**: `${var.environment}-${var.project_name}`
- All variables and outputs must have descriptions
- All variables must have types

## Common Patterns

### Local Variables

Each module uses consistent local variables:
```hcl
locals {
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  }

  resource_prefix = "${var.environment}-${var.project_name}"
}
```

### Standard Variables

All patterns accept these core variables:
- `project_id`: GCP project ID
- `region`: Primary region (default: `asia-northeast1`)
- `environment`: Environment name (dev/prod)
- `project_name`: Project identifier for resource naming

### Monitoring Pattern

All patterns include:
- Alert policies for failures and resource issues
- Notification channels (email, Slack, etc.)
- Cloud Monitoring dashboards
- Structured logging with severity levels

## Testing

Tests use Terraform's native test framework (`terraform test`):

```
tests/
├── variables_validation.tftest.hcl  # Variable validation tests
├── service_accounts.tftest.hcl      # Service account tests
├── pubsub.tftest.hcl                # Pub/Sub tests
├── cloudrun.tftest.hcl              # Cloud Run tests
├── monitoring.tftest.hcl            # Monitoring tests
└── outputs.tftest.hcl               # Output tests
```

Run tests:
```bash
terraform test -test-directory=tests
```
