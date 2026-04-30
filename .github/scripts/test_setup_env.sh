#!/bin/bash
set -u

# Test script for .github/scripts/setup-env.sh

SCRIPT_DIR=$(dirname "$0")
SETUP_SCRIPT="${SCRIPT_DIR}/setup-env.sh"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

export PATH="${TEMP_DIR}:$PATH"

# Helper to create a mock gcloud command
create_mock_gcloud() {
  cat << 'EOF' > "${TEMP_DIR}/gcloud"
#!/bin/bash
if [[ "$*" == *"config get-value project"* ]]; then
  echo "${MOCK_GCP_PROJECT_ID-mock-project}"
elif [[ "$*" == *"config get-value compute/region"* ]]; then
  echo "mock-region"
elif [[ "$*" == *"config set project"* ]]; then
  if [[ "${MOCK_GCLOUD_FAIL_SET_PROJECT:-false}" == "true" ]]; then
    exit 1
  fi
elif [[ "$*" == *"config set compute/region"* ]]; then
  if [[ "${MOCK_GCLOUD_FAIL_SET_REGION:-false}" == "true" ]]; then
    exit 1
  fi
elif [[ "$*" == *"config list"* ]]; then
  echo "mock-config"
fi
exit 0
EOF
  chmod +x "${TEMP_DIR}/gcloud"
}

# Helper to create a mock gh command
create_mock_gh() {
  cat << 'EOF' > "${TEMP_DIR}/gh"
#!/bin/bash
if [[ "$*" == *"auth status"* ]]; then
  exit 0
elif [[ "$*" == *"repo view --json owner -q .owner.login"* ]]; then
  echo "mock-org"
elif [[ "$*" == *"repo view --json name -q .name"* ]]; then
  echo "mock-repo"
fi
exit 0
EOF
  chmod +x "${TEMP_DIR}/gh"
}

run_test_1() {
  echo "Running Test Case 1: gcloud config set project fails"
  create_mock_gcloud
  create_mock_gh
  
  export MOCK_GCLOUD_FAIL_SET_PROJECT=true
  export MOCK_GCP_PROJECT_ID="my-project"
  
  OUTPUT=$(printf "\n\n\n\n" | bash "$SETUP_SCRIPT" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    echo "FAIL: Expected script to exit with non-zero status code, but got 0"
    return 1
  fi
  
  if ! echo "$OUTPUT" | grep -q "Error: Failed to set project"; then
    echo "FAIL: Expected error message about failed project set"
    echo "Actual output:"
    echo "$OUTPUT"
    return 1
  fi
  
  echo "PASS: Test Case 1"
  return 0
}

run_test_2() {
  echo "Running Test Case 2: empty project ID"
  create_mock_gcloud
  create_mock_gh
  
  export MOCK_GCLOUD_FAIL_SET_PROJECT=false
  export MOCK_GCP_PROJECT_ID=""
  
  OUTPUT=$(printf "\n\n\n\n" | bash "$SETUP_SCRIPT" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    echo "FAIL: Expected script to exit with non-zero status code, but got 0"
    return 1
  fi
  
  if ! echo "$OUTPUT" | grep -q "Error: GCP_PROJECT_ID cannot be empty"; then
    echo "FAIL: Expected error message about empty project ID"
    echo "Actual output:"
    echo "$OUTPUT"
    return 1
  fi
  
  echo "PASS: Test Case 2"
  return 0
}

run_test_3() {
  echo "Running Test Case 3: positive path"
  create_mock_gcloud
  create_mock_gh
  
  export MOCK_GCLOUD_FAIL_SET_PROJECT=false
  export MOCK_GCP_PROJECT_ID="valid-project"
  
  # Clean up any existing .env
  rm -f .env
  
  OUTPUT=$(printf "\n\n\n\n" | bash "$SETUP_SCRIPT" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -ne 0 ]; then
    echo "FAIL: Expected script to exit with 0, but got $EXIT_CODE"
    echo "Actual output:"
    echo "$OUTPUT"
    return 1
  fi
  
  if [ ! -f .env ]; then
    echo "FAIL: Expected .env file to be created"
    return 1
  fi
  
  # cleanup
  rm -f .env
  
  echo "PASS: Test Case 3"
  return 0
}

FAILURES=0

run_test_1 || ((FAILURES++))
run_test_2 || ((FAILURES++))
run_test_3 || ((FAILURES++))

if [ $FAILURES -gt 0 ]; then
  echo "$FAILURES tests failed"
  exit 1
fi

echo "All tests passed!"
exit 0
