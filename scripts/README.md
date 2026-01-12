# Scripts

This directory contains utility scripts for managing Terraform architecture patterns.

## validate-pattern.sh

Validates a specific architecture pattern by running Terraform format check, validation, linting, and tests.

### Usage

```bash
./scripts/validate-pattern.sh <pattern-name>
```

### Example

```bash
# Validate the event-driven pattern
./scripts/validate-pattern.sh event-driven

# Validate other patterns
./scripts/validate-pattern.sh microservices-gke
./scripts/validate-pattern.sh workflow-batch
```

### What it does

The script performs the following validation steps:

1. **Terraform Format Check** (`terraform fmt -check -recursive`)
   - Verifies that all Terraform files are properly formatted
   - Fails if any files need formatting
   - Fix with: `terraform fmt -recursive`

2. **Terraform Validate** (`terraform validate`)
   - Validates Terraform configuration syntax and logic
   - Runs for each environment (if environments directory exists)
   - Initializes without backend for validation

3. **TFLint** (optional, `tflint`)
   - Runs TFLint on all modules and root configuration
   - Checks for best practices and potential issues
   - Skipped if TFLint is not installed (with warning)
   - Install TFLint: https://github.com/terraform-linters/tflint

4. **Terraform Test** (`terraform test`)
   - Runs all `*.tftest.hcl` test files
   - Skipped if no test files are found
   - Reports number of passed/failed tests

### Requirements

- **Terraform**: Required (>= 1.13)
- **TFLint**: Optional (recommended for best practices checks)
- **Git**: Required (script uses `git rev-parse` to find repo root)

### Exit Codes

- `0`: All validations passed
- `1`: Validation failed (with colored error message)

### Output

The script provides colored output:
- 🟢 Green: Success
- 🔴 Red: Error
- 🟡 Yellow: Warning/Info
