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

SA_NAME="sa-gh-actions"
SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

echo "Granting roles to $SA_EMAIL..."

ROLES=(
    "roles/editor" # Broad role for terraform deployment, consider narrowing down for production
    "roles/resourcemanager.projectIamAdmin"
    "roles/secretmanager.admin"
    "roles/storage.admin"
    "roles/artifactregistry.admin"
    "roles/run.admin"
    "roles/cloudbuild.builds.editor"
    "roles/iam.serviceAccountUser"
    "roles/datastore.owner"
    "roles/aiplatform.user"
)

for role in "${ROLES[@]}"; do
    echo "Adding role: $role"
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="$role" \
        --condition=None >/dev/null
done

echo "IAM roles granted to $SA_EMAIL."

# Grant roles to the default Compute Engine service account used by Cloud Build
PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT_ID" --format="value(projectNumber)")
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

echo "Granting roles to default Compute SA: $COMPUTE_SA..."

COMPUTE_ROLES=(
    "roles/storage.admin"
    "roles/datastore.owner"
    "roles/logging.logWriter"
    "roles/cloudsql.client"
    "roles/cloudsql.viewer"
    "roles/artifactregistry.writer"
    "roles/artifactregistry.admin"
    "roles/aiplatform.admin"
    "roles/run.admin"
    "roles/resourcemanager.projectIamAdmin"
    "roles/iam.serviceAccountUser"
    "roles/iam.serviceAccountAdmin"
)

for role in "${COMPUTE_ROLES[@]}"; do
    echo "Adding role: $role to $COMPUTE_SA"
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:${COMPUTE_SA}" \
        --role="$role" \
        --condition=None >/dev/null

    echo "Adding role: $role to $CLOUDBUILD_SA"
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:${CLOUDBUILD_SA}" \
        --role="$role" \
        --condition=None >/dev/null
done

echo "IAM roles granted to $COMPUTE_SA and $CLOUDBUILD_SA."