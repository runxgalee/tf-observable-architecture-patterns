# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains production-ready GCP architecture patterns implemented with Terraform. Currently implements the Event-Driven pattern with CI/CD automation. Future patterns (Microservices on GKE, Workflow Batch) are planned.

## Documentation Structure

Detailed guidance is organized into topic-specific rule files in `.claude/rules/`:

1. **[Repository Overview](.claude/rules/01-repository-overview.md)**
   - Architecture patterns (Event-Driven implemented, others planned)
   - Directory structure
   - Configuration files

2. **[Development Workflow](.claude/rules/02-development-workflow.md)**
   - Terraform commands (init, plan, apply, fmt, validate)
   - Backend configuration (partial config with backend.hcl)
   - Bootstrap resources setup
   - TFLint and Terraform Test usage

3. **[CI/CD](.claude/rules/03-ci-cd.md)**
   - GitHub Actions workflows
   - Centralized pattern configuration
   - Secret management (GitHub Secrets + GCP Secret Manager)

4. **[Module Conventions](.claude/rules/04-module-conventions.md)**
   - Architecture pattern structure
   - Module structure and types
   - Naming conventions (snake_case, enforced by TFLint)
   - Common patterns and testing

5. **[Security and Testing](.claude/rules/05-security-testing.md)**
   - Security best practices
   - Terraform native tests
   - CI pipeline checks

## Quick Reference

### Common Commands

```bash
# Navigate to pattern
cd architectures/<pattern>/gcp

# Format and validate
terraform fmt -recursive
terraform init -backend=false
terraform validate

# Initialize with backend
terraform init -backend-config=backend.hcl

# Run TFLint
tflint --init && tflint

# Run Terraform tests
terraform test -test-directory=tests/unit
```

### Key Principles

- **Terraform Version**: Minimum version `>= 1.13` (specified in all `versions.tf` files)
- **Environment Management**: `.auto.tfvars` files for environment-specific values
- **Partial Backend Config**: `backend.hcl` files are git-ignored for security
- **Secrets**: `secrets.auto.tfvars` for sensitive values (git-ignored)
- **Change Detection**: CI/CD only runs for modified architecture patterns
- **Naming Convention**: All identifiers use `snake_case` (enforced by TFLint)
- **Resource Prefix**: `${var.environment}-${var.project_name}`

### File Locations

- Root configs: `architectures/<pattern>/gcp/*.tf`
- Terraform modules: `architectures/<pattern>/gcp/modules/`
- Terraform tests: `architectures/<pattern>/gcp/tests/unit/`
- CI/CD workflows: `.github/workflows/`
- Bootstrap resources: `bootstrap/gcp/`
- Documentation: `docs/`
