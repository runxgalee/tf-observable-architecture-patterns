#!/bin/bash

# Script to validate all Terraform patterns
# Usage: ./scripts/validate-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "========================================="
echo "Validating All Terraform Patterns"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TOTAL_PATTERNS=0
PASSED_PATTERNS=0
FAILED_PATTERNS=0
WARNING_PATTERNS=0

# Get all patterns
PATTERNS=$(find patterns -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

for pattern in $PATTERNS; do
    ((TOTAL_PATTERNS++))

    echo ""
    echo "========================================="
    echo "Pattern: $pattern"
    echo "========================================="

    if ./scripts/validate-pattern.sh "$pattern"; then
        if [ $? -eq 0 ]; then
            ((PASSED_PATTERNS++))
            echo -e "${GREEN}✓ Pattern '$pattern' passed validation${NC}"
        fi
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 1 ]; then
            ((FAILED_PATTERNS++))
            echo -e "${RED}✗ Pattern '$pattern' failed validation${NC}"
        fi
    fi
done

echo ""
echo "========================================="
echo "Final Summary"
echo "========================================="
echo ""
echo "Total patterns: $TOTAL_PATTERNS"
echo -e "${GREEN}Passed: $PASSED_PATTERNS${NC}"
echo -e "${RED}Failed: $FAILED_PATTERNS${NC}"
echo ""

if [ $FAILED_PATTERNS -eq 0 ]; then
    echo -e "${GREEN}✓ All patterns passed validation!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some patterns failed validation${NC}"
    exit 1
fi
