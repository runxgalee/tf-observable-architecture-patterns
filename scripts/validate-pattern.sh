#!/bin/bash
set -e

# Usage: ./scripts/validate-pattern.sh <pattern-name>
# Example: ./scripts/validate-pattern.sh event-driven

PATTERN=$1
REPO_ROOT=$(git rev-parse --show-toplevel)
PATTERN_DIR="${REPO_ROOT}/architectures/${PATTERN}/gcp"
TRIVY_VERSION="0.58.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$PATTERN" ]; then
  echo -e "${RED}Error: Pattern name is required${NC}"
  echo "Usage: $0 <pattern-name>"
  echo "Available patterns:"
  for dir in "${REPO_ROOT}/architectures/"*/gcp; do
    if [ -d "$dir" ]; then
      pattern_name=$(basename "$(dirname "$dir")")
      echo "  - $pattern_name"
    fi
  done
  exit 1
fi

if [ ! -d "$PATTERN_DIR" ]; then
  echo -e "${RED}Error: Pattern directory not found: ${PATTERN_DIR}${NC}"
  echo "Available patterns:"
  for dir in "${REPO_ROOT}/architectures/"*/gcp; do
    if [ -d "$dir" ]; then
      pattern_name=$(basename "$(dirname "$dir")")
      echo "  - $pattern_name"
    fi
  done
  exit 1
fi

echo -e "${GREEN}=== Validating pattern: ${PATTERN} ===${NC}"
echo -e "Pattern directory: ${PATTERN_DIR}\n"

# Step 1: Terraform Format Check
echo -e "${YELLOW}[1/5] Running terraform fmt...${NC}"
cd "$PATTERN_DIR"
if terraform fmt -check -recursive; then
  echo -e "${GREEN}✓ Format check passed${NC}\n"
else
  echo -e "${RED}✗ Format check failed. Run 'terraform fmt -recursive' to fix${NC}\n"
  exit 1
fi

# Step 2: Terraform Validate
echo -e "${YELLOW}[2/5] Running terraform validate...${NC}"
for env_dir in "${PATTERN_DIR}"/environments/*/; do
  if [ -d "$env_dir" ]; then
    env_name=$(basename "$env_dir")
    echo "  Validating environment: $env_name"
    cd "$env_dir"

    # Initialize without backend for validation
    terraform init -backend=false > /dev/null 2>&1

    if terraform validate; then
      echo -e "${GREEN}  ✓ Validation passed for $env_name${NC}"
    else
      echo -e "${RED}  ✗ Validation failed for $env_name${NC}"
      exit 1
    fi
  fi
done

# If no environments directory exists, validate from root
if [ ! -d "${PATTERN_DIR}/environments" ]; then
  echo "  No environments directory found, validating from pattern root"
  cd "$PATTERN_DIR"
  terraform init -backend=false > /dev/null 2>&1

  if terraform validate; then
    echo -e "${GREEN}  ✓ Validation passed${NC}"
  else
    echo -e "${RED}  ✗ Validation failed${NC}"
    exit 1
  fi
fi

echo ""

# Step 3: TFLint
echo -e "${YELLOW}[3/5] Running tflint...${NC}"
cd "$PATTERN_DIR"

# Check if tflint is installed
if ! command -v tflint &> /dev/null; then
  echo -e "${YELLOW}  ⊘ TFLint not found, skipping (install: https://github.com/terraform-linters/tflint)${NC}"
else
  # Initialize tflint if needed
  if [ ! -d .tflint.d ]; then
    echo "  Initializing tflint..."
    if ! tflint --init > /dev/null 2>&1; then
      echo -e "${YELLOW}  ⊘ TFLint initialization failed, skipping${NC}"
    fi
  fi

  # Run tflint on modules
  if [ -d modules ]; then
    echo "  Linting modules..."
    for module_dir in modules/*/; do
      if [ -d "$module_dir" ]; then
        module_name=$(basename "$module_dir")
        cd "$module_dir"
        if tflint --format compact; then
          echo -e "${GREEN}  ✓ TFLint passed for module: $module_name${NC}"
        else
          echo -e "${RED}  ✗ TFLint failed for module: $module_name${NC}"
          exit 1
        fi
        cd "$PATTERN_DIR"
      fi
    done
  fi

  # Run tflint on root configuration
  echo "  Linting root configuration..."
  if tflint --format compact; then
    echo -e "${GREEN}  ✓ TFLint passed for root configuration${NC}"
  else
    echo -e "${RED}  ✗ TFLint failed for root configuration${NC}"
    exit 1
  fi
fi

echo ""

# Step 4: Trivy Security Scan (Docker-based)
echo -e "${YELLOW}[4/5] Running trivy security scan...${NC}"
cd "$PATTERN_DIR"

if ! command -v docker &> /dev/null; then
  echo -e "${YELLOW}  ⊘ Docker not found, skipping Trivy scan (install Docker to enable)${NC}"
elif ! docker info > /dev/null 2>&1; then
  echo -e "${YELLOW}  ⊘ Docker daemon not running, skipping Trivy scan${NC}"
else
  echo "  Using Trivy ${TRIVY_VERSION} via Docker..."

  if docker run --rm -v "${REPO_ROOT}:/work" "aquasec/trivy:${TRIVY_VERSION}" config \
    --severity CRITICAL,HIGH \
    --exit-code 1 \
    "/work/architectures/${PATTERN}/gcp" 2>&1; then
    echo -e "${GREEN}  ✓ Trivy security scan passed${NC}"
  else
    echo -e "${RED}  ✗ Trivy found security issues${NC}"
    exit 1
  fi
fi

echo ""

# Step 5: Terraform Test (if test files exist)
echo -e "${YELLOW}[5/5] Running terraform test...${NC}"
cd "$PATTERN_DIR"

# Check for test files in tests directory
test_files_found=false
if [ -d "tests" ] && find tests -name "*.tftest.hcl" -type f | grep -q .; then
  test_files_found=true
  test_count=$(find tests -name "*.tftest.hcl" -type f | wc -l | tr -d ' ')
  echo "  Found $test_count test file(s) in tests/"

  # Initialize for testing
  terraform init -backend=false > /dev/null 2>&1

  if terraform test -test-directory=tests; then
    echo -e "${GREEN}  ✓ Tests passed${NC}"
  else
    echo -e "${RED}  ✗ Tests failed${NC}"
    exit 1
  fi
fi

if [ "$test_files_found" = false ]; then
  echo -e "${YELLOW}  ⊘ No test files found in tests/ (*.tftest.hcl)${NC}"
fi

echo ""
echo -e "${GREEN}=== All validations passed for pattern: ${PATTERN} ===${NC}"
