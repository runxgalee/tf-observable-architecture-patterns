#!/bin/bash

# Script to detect which architectures have changed
# Usage: ./scripts/detect-changed-architectures.sh [base_ref] [head_ref]
# Example: ./scripts/detect-changed-architectures.sh main HEAD
# Example: ./scripts/detect-changed-architectures.sh HEAD~1 HEAD

set -e

BASE_REF=${1:-"HEAD~1"}
HEAD_REF=${2:-"HEAD"}

echo "Detecting changes between $BASE_REF and $HEAD_REF"
echo "================================================"
echo ""

# Get changed files
CHANGED_FILES=$(git diff --name-only "$BASE_REF" "$HEAD_REF")

if [ -z "$CHANGED_FILES" ]; then
    echo "No changes detected"
    exit 0
fi

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Extract architectures
PATTERNS=$(echo "$CHANGED_FILES" | grep '^architectures/' | cut -d'/' -f2 | sort -u)

if [ -z "$PATTERNS" ]; then
    echo "No pattern changes detected"
    exit 0
fi

echo "Changed patterns:"
echo "$PATTERNS"
echo ""

# Get environments for each pattern
echo "Affected environments:"
echo "====================="
for pattern in $PATTERNS; do
    echo ""
    echo "Pattern: $pattern"

    if [ -d "architectures/$pattern/gcp/environments" ]; then
        ENVIRONMENTS=$(ls -1 "architectures/$pattern/gcp/environments" 2>/dev/null || echo "")
        if [ -n "$ENVIRONMENTS" ]; then
            for env in $ENVIRONMENTS; do
                if [ -d "architectures/$pattern/gcp/environments/$env" ]; then
                    echo "  - $env (architectures/$pattern/gcp/environments/$env)"
                fi
            done
        else
            echo "  No environments found"
        fi
    else
        echo "  No environments directory found"
    fi
done

echo ""
echo "Summary:"
echo "========"
PATTERN_COUNT=$(echo "$PATTERNS" | wc -l | tr -d ' ')
echo "Total patterns changed: $PATTERN_COUNT"

# Output JSON format for GitHub Actions compatibility
echo ""
echo "GitHub Actions Matrix JSON:"
PATTERNS_JSON=$(echo "$PATTERNS" | jq -R -s -c 'split("\n") | map(select(length > 0))')
echo "$PATTERNS_JSON"
