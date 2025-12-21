#!/bin/bash

# Script to set up GCP Workload Identity Federation for GitHub Actions
# Usage: ./scripts/setup-gcp-wif.sh

set -e

echo "GCP Workload Identity Federation Setup for GitHub Actions"
echo "=========================================================="
echo ""

# Check if required commands are available
command -v gcloud >/dev/null 2>&1 || { echo "Error: gcloud is not installed"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is not installed"; exit 1; }

# Prompt for required information
read -p "Enter GCP Project ID: " PROJECT_ID
read -p "Enter GitHub Organization/Username: " GITHUB_ORG
read -p "Enter GitHub Repository Name: " GITHUB_REPO

echo ""
echo "Configuration:"
echo "  GCP Project ID: $PROJECT_ID"
echo "  GitHub Org: $GITHUB_ORG"
echo "  GitHub Repo: $GITHUB_REPO"
echo ""

read -p "Is this correct? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Aborted"
    exit 1
fi

echo ""
echo "Getting project number..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
echo "Project number: $PROJECT_NUMBER"

echo ""
echo "Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  2>/dev/null || echo "Pool already exists, continuing..."

echo ""
echo "Creating Workload Identity Provider..."
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  2>/dev/null || echo "Provider already exists, continuing..."

echo ""
echo "Creating Service Account..."
gcloud iam service-accounts create github-actions-terraform \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Terraform" \
  2>/dev/null || echo "Service account already exists, continuing..."

SERVICE_ACCOUNT="github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "Granting permissions to Service Account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/editor" \
  --condition=None

echo ""
echo "Setting up Workload Identity Federation binding..."
gcloud iam service-accounts add-iam-policy-binding \
  "${SERVICE_ACCOUNT}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

echo ""
echo "Getting Workload Identity Provider name..."
WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)")

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Add the following secrets to your GitHub repository:"
echo "  Repository: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
echo ""
echo "WIF_PROVIDER:"
echo "$WIF_PROVIDER"
echo ""
echo "WIF_SERVICE_ACCOUNT:"
echo "$SERVICE_ACCOUNT"
echo ""
echo "=========================================="
echo ""
echo "To copy to clipboard (macOS):"
echo "  echo '$WIF_PROVIDER' | pbcopy"
echo "  echo '$SERVICE_ACCOUNT' | pbcopy"
echo ""
