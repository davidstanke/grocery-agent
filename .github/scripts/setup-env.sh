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

if ! command -v gh > /dev/null
then
  echo "bash: gh: command not found"
  echo "Consider installing gh cli at: https://github.com/cli/cli#installation"
fi

# figure out if we're logged into the gh CLI
GH_AVAILABLE=false
if gh auth status > /dev/null 2>&1; then
  GH_AVAILABLE=true
fi

if [ "$GH_AVAILABLE" = true ]; then
  echo "gh: command found and logged into GitHub"
fi

# Obtain possible defaults of key environment variables:
_GITHUB_ORG=""
_GITHUB_REPO="agent-farm"
if [ "$GH_AVAILABLE" = true ]; then
  _GITHUB_ORG=$(gh repo view --json owner -q ".owner.login")
  _GITHUB_REPO=$(gh repo view --json name -q ".name")
fi
_GCP_SA_GITHUB_ACTIONS="sa-gh-actions"
_GCP_PROJECT_ID=$(gcloud config get-value project)
_GCP_LOCATION=$(gcloud config get-value compute/region)
_GCP_LOCATION=${_GCP_LOCATION:-us-central1}

# Request acceptance of defaults or alternatives
read -r -p "Enter GitHub organization or owner [${_GITHUB_ORG}]: " GITHUB_ORG
read -r -p "Enter GitHub repository name [${_GITHUB_REPO}]: " GITHUB_REPO
read -r -p "Enter GCP project ID [${_GCP_PROJECT_ID}]: " GCP_PROJECT_ID
read -r -p "Enter default value region for this setup [${_GCP_LOCATION}]: " GCP_LOCATION

GITHUB_ORG="${GITHUB_ORG:-${_GITHUB_ORG}}"
GITHUB_REPO="${GITHUB_REPO:-${_GITHUB_REPO}}"
GCP_SA_GITHUB_ACTIONS="${GCP_SA_GITHUB_ACTIONS:-${_GCP_SA_GITHUB_ACTIONS}}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-${_GCP_PROJECT_ID}}"
GCP_LOCATION="${GCP_LOCATION:-${_GCP_LOCATION}}"

if [ -z "${GCP_PROJECT_ID}" ]; then
  echo "Error: GCP_PROJECT_ID cannot be empty." >&2
  exit 1
fi

if ! gcloud config set project "${GCP_PROJECT_ID}"; then
  echo "Error: Failed to set project. Ensure you are authenticated using 'gcloud auth login' and the project exists." >&2
  exit 1
fi

if ! gcloud config set compute/region "${GCP_LOCATION}"; then
  echo "Error: Failed to set compute/region." >&2
  exit 1
fi

if [ "$GH_AVAILABLE" = true ]; then
  gh repo set-default "${GITHUB_ORG}/${GITHUB_REPO}"
fi

if ! GCLOUD_CONFIG=$(gcloud config list); then
  echo "Error: Failed to list gcloud config." >&2
  exit 1
fi

cat << EOF

----------------------------------------
-------- GOOGLE CLOUD CONFIGURED -------
----------------------------------------

${GCLOUD_CONFIG}

----------------------------------------
----- GITHUB ACTIONS ENV KEY/VALUE -----
----------------------------------------

GITHUB_ORG:            ${GITHUB_ORG}
GITHUB_REPO:           ${GITHUB_REPO}
GCP_SA_GITHUB_ACTIONS: ${GCP_SA_GITHUB_ACTIONS}
GCP_PROJECT_ID:        ${GCP_PROJECT_ID}
GCP_LOCATION:          ${GCP_LOCATION}

EOF

cat << EOF > .env
GITHUB_ORG="${GITHUB_ORG}"
GITHUB_REPO="${GITHUB_REPO}"
GCP_SA_GITHUB_ACTIONS="${GCP_SA_GITHUB_ACTIONS}"
GCP_PROJECT_ID="${GCP_PROJECT_ID}"
GCP_LOCATION="${GCP_LOCATION}"
EOF