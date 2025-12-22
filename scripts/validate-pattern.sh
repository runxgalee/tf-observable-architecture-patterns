#!/bin/bash

# Script to validate a Terraform pattern
# Usage: ./scripts/validate-pattern.sh <pattern-name>
# Example: ./scripts/validate-pattern.sh event-driven

set -e

PATTERN=${1:-}

if [ -z "$PATTERN" ]; then
    echo "Error: Pattern name is required"
    echo "Usage: $0 <pattern-name>"
    echo ""
    echo "Available patterns:"
    ls -1 architectures/
    exit 1
fi

PATTERN_PATH="architectures/$PATTERN/gcp"

if [ ! -d "$PATTERN_PATH" ]; then
    echo "Error: Pattern '$PATTERN' not found at $PATTERN_PATH"
    exit 1
fi

echo "========================================="
echo "Validating Pattern: $PATTERN"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print success
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

echo "1. Checking directory structure..."
echo "-----------------------------------"

# Check for modules directory
if [ -d "$PATTERN_PATH/modules" ]; then
    success "modules/ directory exists"
else
    error "modules/ directory not found"
fi

# Check for environments directory
if [ -d "$PATTERN_PATH/environments" ]; then
    success "environments/ directory exists"
else
    error "environments/ directory not found"
fi

# Check for dev and prod environments
for env in dev prod; do
    if [ -d "$PATTERN_PATH/environments/$env" ]; then
        success "environments/$env exists"
    else
        error "environments/$env not found"
    fi
done

echo ""
echo "2. Checking required files..."
echo "-----------------------------------"

# Check for README
if [ -f "$PATTERN_PATH/README.md" ]; then
    success "README.md exists"
else
    warning "README.md not found"
fi

# Check module files
MODULE_DIRS=$(find "$PATTERN_PATH/modules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || echo "")
if [ -n "$MODULE_DIRS" ]; then
    for module in $MODULE_DIRS; do
        module_name=$(basename "$module")
        echo ""
        echo "Checking module: $module_name"

        for file in versions.tf main.tf variables.tf outputs.tf; do
            if [ -f "$module/$file" ]; then
                success "$module_name/$file exists"
            else
                if [ "$file" == "versions.tf" ] || [ "$file" == "main.tf" ]; then
                    error "$module_name/$file not found (required)"
                else
                    warning "$module_name/$file not found (recommended)"
                fi
            fi
        done
    done
fi

# Check environment files
for env in dev prod; do
    ENV_PATH="$PATTERN_PATH/environments/$env"
    if [ -d "$ENV_PATH" ]; then
        echo ""
        echo "Checking environment: $env"

        for file in providers.tf backend.tf main.tf variables.tf outputs.tf; do
            if [ -f "$ENV_PATH/$file" ]; then
                success "$env/$file exists"
            else
                if [ "$file" == "main.tf" ] || [ "$file" == "providers.tf" ]; then
                    error "$env/$file not found (required)"
                else
                    warning "$env/$file not found (recommended)"
                fi
            fi
        done
    fi
done

echo ""
echo "3. Running terraform fmt..."
echo "-----------------------------------"
cd "$PATTERN_PATH"
if terraform fmt -check -recursive; then
    success "All files are properly formatted"
else
    error "Format check failed. Run 'terraform fmt -recursive' to fix"
fi

echo ""
echo "4. Validating Terraform syntax..."
echo "-----------------------------------"

# Validate modules
if [ -d "modules" ]; then
    for module in modules/*/; do
        if [ -d "$module" ]; then
            module_name=$(basename "$module")
            echo "Validating module: $module_name"
            cd "$module"
            if terraform init -backend=false > /dev/null 2>&1; then
                if terraform validate > /dev/null 2>&1; then
                    success "Module $module_name is valid"
                else
                    error "Module $module_name validation failed"
                    terraform validate
                fi
            else
                error "Module $module_name init failed"
            fi
            cd - > /dev/null
        fi
    done
fi

# Validate environments
for env in dev prod; do
    ENV_PATH="environments/$env"
    if [ -d "$ENV_PATH" ]; then
        echo "Validating environment: $env"
        cd "$ENV_PATH"
        if terraform init -backend=false > /dev/null 2>&1; then
            if terraform validate > /dev/null 2>&1; then
                success "Environment $env is valid"
            else
                error "Environment $env validation failed"
                terraform validate
            fi
        else
            error "Environment $env init failed"
        fi
        cd - > /dev/null
    fi
done

echo ""
echo "5. Running TFLint..."
echo "-----------------------------------"

if command -v tflint >/dev/null 2>&1; then
    cd "$PATTERN_PATH"
    if tflint --init > /dev/null 2>&1; then
        if tflint --format compact; then
            success "TFLint passed"
        else
            warning "TFLint found issues"
        fi
    else
        warning "TFLint init failed"
    fi
else
    warning "TFLint not installed, skipping"
fi

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
