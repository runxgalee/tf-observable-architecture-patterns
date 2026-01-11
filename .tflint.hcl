# TFLint Configuration for GCP Architecture Patterns
#
# This configuration enforces Terraform best practices and code quality standards
# across all architecture patterns in this repository.
#
# Usage:
#   cd architectures/<pattern>/gcp
#   tflint --init
#   tflint

# =============================================================================
# Plugins
# =============================================================================

# Terraform plugin with recommended preset
# Enables a curated set of rules for general Terraform best practices
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Google Cloud Platform plugin
# Provides GCP-specific rules for resource validation and best practices
# Version is pinned to ensure consistent behavior across environments
plugin "google" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# =============================================================================
# Naming Convention
# =============================================================================

# Enforce snake_case naming convention across all Terraform identifiers
# This ensures consistency and readability throughout the codebase
rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }
}

# =============================================================================
# Code Quality Rules
# =============================================================================

# Detect deprecated interpolation syntax: "${var.x}" should be just var.x
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Require description attribute for all outputs
rule "terraform_documented_outputs" {
  enabled = true
}

# Require description attribute for all variables
rule "terraform_documented_variables" {
  enabled = true
}

# Require type attribute for all variables
rule "terraform_typed_variables" {
  enabled = true
}

# Require version pinning for external module sources
rule "terraform_module_pinned_source" {
  enabled = true
}

# Detect unused variables, locals, and data sources
rule "terraform_unused_declarations" {
  enabled = true
}

# Enforce # comment style (not // which is valid but less common)
rule "terraform_comment_syntax" {
  enabled = true
}

# =============================================================================
# Module Structure Rules
# =============================================================================

# Require required_version in terraform block
rule "terraform_required_version" {
  enabled = true
}

# Require required_providers block with version constraints
rule "terraform_required_providers" {
  enabled = true
}

# Validate standard module structure (main.tf, variables.tf, outputs.tf)
rule "terraform_standard_module_structure" {
  enabled = true
}
