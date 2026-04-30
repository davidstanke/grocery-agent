#!/bin/bash
set -euo pipefail

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Source environment variables from .env file (see scripts/setup-env.sh)
if [ -f .env ]; then
  # shellcheck source=/dev/null
  source .env
fi

if [ -z "${GCP_PROJECT_ID:-}" ]; then
    echo "Error: GCP_PROJECT_ID environment variable is not set."
    exit 1
fi

GITHUB_ORG="${GITHUB_ORG:-<your-github-username>}" # Change this manually or pass via env
GITHUB_REPO="${GITHUB_REPO:-<your-repo-name>}"      # Change this manually or pass via env

if [ "$GITHUB_ORG" == "<your-github-username>" ]; then
    echo "Error: Please edit this script to set your GITHUB_ORG and GITHUB_REPO, or provide them via environment variables."
    exit 1
fi

SA_NAME="sa-gh-actions"
SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-actions-provider"

echo "Setting up Workload Identity Federation for GitHub Actions..."

# 1. Create the Service Account
if gcloud iam service-accounts describe "$SA_EMAIL" --project="${GCP_PROJECT_ID}" >/dev/null 2>&1; then
    echo "Service account $SA_NAME already exists."
else
    gcloud iam service-accounts create "$SA_NAME" \
        --project="${GCP_PROJECT_ID}" \
        --display-name="GitHub Actions Deployment Service Account"
fi

# 2. Create the Workload Identity Pool
if gcloud iam workload-identity-pools describe "$POOL_NAME" --project="${GCP_PROJECT_ID}" --location="global" >/dev/null 2>&1; then
    echo "Workload identity pool $POOL_NAME already exists."
else
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="${GCP_PROJECT_ID}" \
        --location="global" \
        --display-name="GitHub Actions Pool"
fi

# 3. Create the Workload Identity Provider
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project="${GCP_PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" >/dev/null 2>&1; then
    echo "Workload identity provider $PROVIDER_NAME already exists."
else
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
        --project="${GCP_PROJECT_ID}" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --display-name="GitHub Actions Provider" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
        --attribute-condition="assertion.repository == '${GITHUB_ORG}/${GITHUB_REPO}'" \
        --issuer-uri="https://token.actions.githubusercontent.com"
fi

# Get the Project Number
PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT_ID" --format="value(projectNumber)")

# 4. Allow the GitHub repo to impersonate the Service Account
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --project="${GCP_PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# Get the Provider ID
PROVIDER_ID="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

echo ""
echo "----- GITHUB ACTIONS ENV KEY/VALUE -----"
echo ""
echo "GCP_SA_GITHUB_ACTIONS: $SA_NAME"
echo "GCP_PROJECT_ID: $GCP_PROJECT_ID"
echo "GCP_LOCATION: ${GCP_LOCATION:-us-central1}"
echo "GCP_WI_PROVIDER_ID: $PROVIDER_ID"
echo ""
echo "----------------------------------------"
echo "Add these values to your GitHub repository variables."
echo "----------------------------------------"
echo ""