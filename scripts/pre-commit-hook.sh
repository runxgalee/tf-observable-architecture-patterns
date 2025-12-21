#!/bin/bash

# Pre-commit hook for Terraform validation
# Install: cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

echo "Running pre-commit Terraform validation..."
echo ""

# Get changed Terraform files
CHANGED_TF_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.tf$' || true)

if [ -z "$CHANGED_TF_FILES" ]; then
    echo "No Terraform files changed, skipping validation"
    exit 0
fi

echo "Changed Terraform files:"
echo "$CHANGED_TF_FILES"
echo ""

# Extract patterns from changed files
PATTERNS=$(echo "$CHANGED_TF_FILES" | grep '^patterns/' | cut -d'/' -f2 | sort -u || true)

if [ -z "$PATTERNS" ]; then
    echo "No pattern files changed, skipping validation"
    exit 0
fi

echo "Patterns to validate:"
echo "$PATTERNS"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

FAILED=0

# Run format check on changed files
echo "1. Checking Terraform format..."
echo "--------------------------------"
for file in $CHANGED_TF_FILES; do
    if [ -f "$file" ]; then
        if terraform fmt -check "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${RED}✗${NC} $file (not formatted)"
            echo "  Run: terraform fmt $file"
            FAILED=1
        fi
    fi
done

# Validate each pattern
echo ""
echo "2. Validating patterns..."
echo "--------------------------------"
for pattern in $PATTERNS; do
    echo "Validating: $pattern"
    if ./scripts/validate-pattern.sh "$pattern" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $pattern passed validation"
    else
        echo -e "${RED}✗${NC} $pattern failed validation"
        echo "  Run: ./scripts/validate-pattern.sh $pattern"
        FAILED=1
    fi
done

echo ""
if [ $FAILED -eq 1 ]; then
    echo -e "${RED}✗ Pre-commit validation failed${NC}"
    echo ""
    echo "To skip this hook (not recommended):"
    echo "  git commit --no-verify"
    exit 1
else
    echo -e "${GREEN}✓ Pre-commit validation passed${NC}"
    exit 0
fi
