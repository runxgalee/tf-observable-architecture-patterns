# Scripts

This directory contains utility scripts for managing Terraform architecture patterns.

## validate-pattern.sh

Validates a specific architecture pattern by running Terraform format check, validation, linting, security scan, and tests.

### Usage

```bash
./scripts/validate-pattern.sh <pattern-name>
```

### Example

```bash
# Validate the event-driven pattern
./scripts/validate-pattern.sh event-driven

# Show available patterns (no argument)
./scripts/validate-pattern.sh
```

### What it does

The script performs the following 5 validation steps:

| Step | Command | Description |
|------|---------|-------------|
| 1/5 | `terraform fmt -check -recursive` | Format check |
| 2/5 | `terraform validate` | Configuration validation |
| 3/5 | `tflint` | Linting (modules + root) |
| 4/5 | `trivy config` | Security scan via Docker |
| 5/5 | `terraform test` | Native Terraform tests |

#### 1. Terraform Format Check

- Verifies all Terraform files are properly formatted
- Fails if any files need formatting
- Fix with: `terraform fmt -recursive`

#### 2. Terraform Validate

- Validates Terraform configuration syntax and logic
- Runs for each environment (if `environments/` directory exists)
- Otherwise validates from pattern root
- Initializes without backend (`-backend=false`)

#### 3. TFLint

- Runs TFLint on all modules and root configuration
- Checks for best practices and potential issues
- Skipped if TFLint is not installed (with warning)
- Install: https://github.com/terraform-linters/tflint

#### 4. Trivy Security Scan

- Runs Trivy security scanner via Docker
- Checks for CRITICAL and HIGH severity issues
- Scans for misconfigurations and security vulnerabilities
- Skipped if Docker is not available or not running
- Uses Trivy version: `0.58.0`

#### 5. Terraform Test

- Runs all `*.tftest.hcl` test files in `tests/` directory
- Skipped if no test files are found
- Reports number of passed/failed tests

### Requirements

| Tool | Required | Notes |
|------|----------|-------|
| Terraform | Yes | >= 1.13 |
| Git | Yes | Used to find repo root |
| TFLint | No | Recommended for best practices |
| Docker | No | Required for Trivy security scan |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All validations passed |
| `1` | Validation failed |

### Output

The script provides colored output:

| Color | Meaning |
|-------|---------|
| Green | Success |
| Red | Error |
| Yellow | Warning / Info / Skipped |

### Sample Output

```
=== Validating pattern: event-driven ===
Pattern directory: /path/to/architectures/event-driven/gcp

[1/5] Running terraform fmt...
✓ Format check passed

[2/5] Running terraform validate...
  No environments directory found, validating from pattern root
  ✓ Validation passed

[3/5] Running tflint...
  Linting modules...
  ✓ TFLint passed for module: cloudrun
  ✓ TFLint passed for module: iam_bindings
  ✓ TFLint passed for module: monitoring
  ✓ TFLint passed for module: observability
  ✓ TFLint passed for module: pubsub
  ✓ TFLint passed for module: service_accounts
  Linting root configuration...
  ✓ TFLint passed for root configuration

[4/5] Running trivy security scan...
  Using Trivy 0.58.0 via Docker...
  ✓ Trivy security scan passed

[5/5] Running terraform test...
  Found 2 test file(s) in tests/
  ✓ Tests passed

=== All validations passed for pattern: event-driven ===
```
