#!/bin/bash
set -e

# Usage: ./scripts/pre-commit-terraform.sh <check-type> [files...]
# check-type: fmt, validate, tflint, tflint-modules, test

CHECK_TYPE=$1
shift
FILES=("$@")

REPO_ROOT=$(git rev-parse --show-toplevel)

# Extract unique patterns from changed files
get_patterns() {
  local patterns=()
  for file in "${FILES[@]}"; do
    if [[ "$file" =~ ^architectures/([^/]+)/gcp/ ]]; then
      pattern="${BASH_REMATCH[1]}"
      if [[ ! " ${patterns[*]} " =~ " ${pattern} " ]]; then
        patterns+=("$pattern")
      fi
    fi
  done
  echo "${patterns[@]}"
}

patterns=($(get_patterns))

if [ ${#patterns[@]} -eq 0 ]; then
  echo "No patterns detected from changed files"
  exit 0
fi

for pattern in "${patterns[@]}"; do
  PATTERN_DIR="${REPO_ROOT}/architectures/${pattern}/gcp"

  if [ ! -d "$PATTERN_DIR" ]; then
    echo "Pattern directory not found: $PATTERN_DIR"
    exit 1
  fi

  echo "=== Pattern: ${pattern} ==="

  case "$CHECK_TYPE" in
    fmt)
      echo "Running terraform fmt..."
      cd "$PATTERN_DIR"
      terraform fmt -check -recursive
      ;;

    validate)
      echo "Running terraform validate..."
      cd "$PATTERN_DIR"
      terraform init -backend=false -input=false > /dev/null 2>&1
      terraform validate
      ;;

    tflint)
      echo "Running tflint..."
      cd "$PATTERN_DIR"
      tflint --init > /dev/null 2>&1 || true

      # Lint root configuration
      echo "  Linting root configuration..."
      tflint --format compact

      # Lint modules
      if [ -d "modules" ]; then
        cd modules
        for module in */; do
          if [ -d "$module" ]; then
            echo "  Linting module: $module"
            cd "$module"
            tflint --format compact
            cd ..
          fi
        done
      fi
      ;;

    test)
      echo "Running terraform test..."
      cd "$PATTERN_DIR"
      if [ -d "tests" ] && find tests -name "*.tftest.hcl" -type f | grep -q .; then
        terraform init -backend=false -input=false > /dev/null 2>&1
        terraform test -test-directory=tests
      else
        echo "No test files found, skipping"
      fi
      ;;

    trivy)
      echo "Running trivy security scan..."
      TRIVY_VERSION="0.58.0"

      if ! command -v docker &> /dev/null; then
        echo "Docker not found, skipping Trivy scan"
        exit 0
      fi

      if ! docker info > /dev/null 2>&1; then
        echo "Docker daemon not running, skipping Trivy scan"
        exit 0
      fi

      docker run --rm -v "${REPO_ROOT}:/work" "aquasec/trivy:${TRIVY_VERSION}" config \
        --severity CRITICAL,HIGH \
        --exit-code 1 \
        "/work/architectures/${pattern}/gcp"
      ;;

    *)
      echo "Unknown check type: $CHECK_TYPE"
      echo "Valid types: fmt, validate, tflint, tflint-modules, test, trivy"
      exit 1
      ;;
  esac

  echo ""
done
