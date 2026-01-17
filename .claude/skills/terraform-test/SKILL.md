---
description: Generate Terraform native tests following project conventions. Creates test files for variable validation (boundary tests) and conditional resources (count/dynamic blocks).
triggers:
  - terraform test
  - tftest
  - create terraform test
  - add terraform test
---

# Terraform Test Generator

Generate Terraform native tests (`.tftest.hcl`) following project conventions.

## Test Categories

This project uses two types of tests:

### 1. Variable Validation Tests
For variables with `validation` blocks. Test boundary values:
- Valid minimum/maximum values
- Invalid values below/above boundaries
- Valid enum values
- Invalid enum values

### 2. Conditional Resource Tests
For resources with `count` or `dynamic` blocks. Test:
- Resource creation when enabled (count > 0)
- Resource absence when disabled (count = 0)
- Output values reflecting conditional state

## Test File Structure

```hcl
# [Test Category] Tests
# [Description of what is being tested]

# -----------------------------------------------------------------------------
# Common Test Configuration
# -----------------------------------------------------------------------------
mock_provider "google" {
  override_data {
    target = module.iam_bindings.data.google_project.project
    values = {
      project_id = "test-project"
      number     = "123456789012"
    }
  }
}

variables {
  project_id      = "test-project"
  region          = "asia-northeast1"
  environment     = "dev"
  project_name    = "events"
  container_image = "gcr.io/test/image:latest"
}
# -----------------------------------------------------------------------------

# =============================================================================
# [Variable/Feature Name]: [Constraint Description]
# =============================================================================

run "test_name" {
  command = plan

  variables {
    # Override specific variables for this test
  }

  # For validation tests expecting failure:
  # expect_failures = [var.variable_name]

  # For conditional resource tests:
  assert {
    condition     = <expression>
    error_message = "Description of expected behavior"
  }
}
```

## Instructions

1. **Analyze the Terraform configuration**:
   - Find variables with `validation` blocks in `variables.tf`
   - Find resources with `count` or `dynamic` blocks in modules

2. **For Variable Validation Tests**:
   ```hcl
   # Valid boundary test
   run "variable_valid_min" {
     command = plan
     variables { variable_name = <min_valid_value> }
   }

   # Invalid boundary test
   run "variable_invalid_below_min" {
     command = plan
     variables { variable_name = <below_min_value> }
     expect_failures = [var.variable_name]
   }
   ```

3. **For Conditional Resource Tests**:
   ```hcl
   run "feature_enabled" {
     command = plan
     variables { enable_feature = true }

     assert {
       condition     = output.related_output != null
       error_message = "Output should be set when feature is enabled"
     }
   }

   run "feature_disabled" {
     command = plan
     variables { enable_feature = false }

     assert {
       condition     = output.related_output == null
       error_message = "Output should be null when feature is disabled"
     }
   }
   ```

4. **Test Location**: `tests/*.tftest.hcl`

5. **Run Tests**:
   ```bash
   cd architectures/<pattern>/gcp
   terraform init -backend=false
   terraform test -test-directory=tests
   ```

## Naming Conventions

- Test file: `<category>.tftest.hcl` (e.g., `variables_validation.tftest.hcl`)
- Run block: `<variable>_<valid|invalid>_<description>` (e.g., `environment_invalid_test`)
- Use snake_case for all identifiers

## Key Points

- Use `command = plan` (not apply) for all tests
- Use `mock_provider` to avoid real API calls
- Each test file has its own Common Test Configuration (not shared)
- Test only what matters: validation rules and conditional logic
- Keep tests focused and minimal
