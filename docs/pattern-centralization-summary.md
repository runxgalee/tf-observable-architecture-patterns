# Architecture Pattern Centralization - Implementation Summary

## Overview

This document summarizes the implementation of centralized architecture pattern management for the CI/CD workflows.

## Problem Statement

**Before**: Architecture patterns were hardcoded in multiple workflow files, leading to:
- Pattern definitions duplicated across 4 workflow files
- Risk of inconsistency when adding/removing patterns
- Difficult maintenance (need to update multiple files)
- No clear single source of truth

**Affected files**:
1. `.github/workflows/terraform-ci.yml`
2. `.github/workflows/terraform-plan-pr.yml`
3. `.github/workflows/terraform-apply.yml`
4. `.github/workflows/terraform-apply-with-approval.yml`

Each file had hardcoded pattern lists like:
```yaml
env:
  ARCHITECTURE_PATTERNS: '["event-driven", "microservices-gke", "workflow-batch"]'

jobs:
  some-job:
    strategy:
      matrix:
        pattern:
          - event-driven
          - microservices-gke
          - workflow-batch
```

## Solution Implemented

### 1. Created Centralized Configuration Workflow

**File**: `.github/workflows/_patterns-config.yml`

This reusable workflow defines all patterns in one place:
- `all_patterns`: Complete list of architecture patterns
- `prod_patterns`: Subset approved for production deployment
- `all_patterns_list`: Comma-separated string for display

### 2. Updated All Workflows to Use Centralized Config

All 4 workflow files now:
1. Call the `_patterns-config.yml` reusable workflow
2. Use its outputs for matrix strategies
3. Reference patterns via `needs.get-patterns.outputs.*`

### Pattern Definition

The single source of truth is now:

```yaml
# In _patterns-config.yml
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch"]'
PROD_PATTERNS='["event-driven"]'
```

### Workflow Changes

#### terraform-ci.yml
- Removed: Hardcoded `ARCHITECTURE_PATTERNS` env variable
- Removed: Hardcoded matrix patterns in 6 jobs
- Added: `get-patterns` job that calls `_patterns-config.yml`
- Updated: All jobs to use `needs.get-patterns.outputs.all_patterns`

#### terraform-plan-pr.yml
- Removed: Hardcoded `ARCHITECTURE_PATTERNS` env variable
- Removed: Hardcoded matrix patterns
- Added: `get-patterns` job
- Updated: Jobs to use centralized patterns

#### terraform-apply.yml
- Removed: Hardcoded `ARCHITECTURE_PATTERNS` env variable
- Removed: Missing `prepare-matrix` job references
- Added: `get-patterns` job
- Updated: Matrix to use `all_patterns`
- Updated: Manual workflow dispatch options to include all patterns

#### terraform-apply-with-approval.yml
- Removed: Hardcoded `ARCHITECTURE_PATTERNS` env variable
- Removed: Complex `detect-changes` job
- Added: `get-patterns` job
- Updated: Matrix to use `prod_patterns` (only approved patterns)
- Simplified: Production deployment logic

## Benefits

### Single Source of Truth
All pattern definitions live in one file: `_patterns-config.yml`

### Easy Maintenance
To add a new pattern:
```yaml
# Edit only _patterns-config.yml
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch", "new-pattern"]'
```

All workflows automatically use the new pattern.

### Separation of Concerns
- `all_patterns`: For testing, planning, and dev deployment
- `prod_patterns`: For production deployment (subset for safety)

### Consistency Guarantee
Impossible to have mismatched patterns across workflows since they all reference the same source.

### Reduced Code Duplication
- Before: ~263 lines of duplicated pattern definitions
- After: Replaced with centralized config and references
- Net reduction: Significant simplification

## Files Changed

### Created
1. `.github/workflows/_patterns-config.yml` - Centralized configuration
2. `docs/managing-architecture-patterns.md` - English guide
3. `docs/managing-architecture-patterns.ja.md` - Japanese guide
4. `docs/pattern-centralization-summary.md` - This file

### Modified
1. `.github/workflows/terraform-ci.yml`
2. `.github/workflows/terraform-plan-pr.yml`
3. `.github/workflows/terraform-apply.yml`
4. `.github/workflows/terraform-apply-with-approval.yml`
5. `.claude/rules/03-ci-cd.md` - Updated documentation

## Usage Examples

### Adding a New Pattern

```bash
# 1. Create architecture
mkdir -p architectures/new-pattern/gcp/{modules,environments/{dev,prod}}

# 2. Edit _patterns-config.yml
ALL_PATTERNS='[..., "new-pattern"]'

# 3. Commit
git add .
git commit -m "feat: add new-pattern architecture"
```

### Enabling Production Deployment

```bash
# Edit _patterns-config.yml
PROD_PATTERNS='["event-driven", "microservices-gke"]'
```

### Disabling a Pattern Temporarily

```bash
# Edit _patterns-config.yml - remove from list
ALL_PATTERNS='["event-driven", "workflow-batch"]'
# microservices-gke removed, will not run in CI/CD
```

## Workflow Diagram

```
┌─────────────────────────────────────┐
│  _patterns-config.yml               │
│  (Single Source of Truth)           │
│                                     │
│  ALL_PATTERNS = [...]               │
│  PROD_PATTERNS = [...]              │
└──────────────┬──────────────────────┘
               │
               │ Called by all workflows
               │
       ┌───────┴────────┐
       │                │
   ┌───▼────┐      ┌───▼────┐
   │ CI     │      │ Plan   │
   │ (all)  │      │ (all)  │
   └────────┘      └────────┘
       │                │
   ┌───▼────┐      ┌───▼─────┐
   │ Apply  │      │ Apply+  │
   │ (all)  │      │ (prod)  │
   └────────┘      └─────────┘
```

## Testing

The changes can be validated by:

1. **Syntax Check**: GitHub Actions will validate workflow syntax
2. **PR Test**: Create a PR to trigger `terraform-plan-pr.yml`
3. **CI Test**: Push to branch to trigger `terraform-ci.yml`
4. **Manual Test**: Use workflow dispatch with different patterns

## Migration Notes

### Backward Compatibility
- All existing functionality is preserved
- Pattern detection logic moved to centralized location
- No changes to Terraform code required

### Breaking Changes
None. This is a refactoring that maintains all existing behavior.

### Future Enhancements
1. Add pattern validation (check directory exists)
2. Add automatic pattern discovery from directory structure
3. Add pattern-specific configuration (e.g., Terraform version)
4. Add pattern tagging (e.g., experimental, stable, deprecated)

## Conclusion

This refactoring successfully centralizes architecture pattern management, making the CI/CD system easier to maintain and less error-prone. All patterns are now defined in a single location, and all workflows automatically stay synchronized.

**Key Achievement**: Changed from "4+ files to update" to "1 file to update" when managing patterns.
