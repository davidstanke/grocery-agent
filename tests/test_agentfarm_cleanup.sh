#!/bin/bash
set -e

echo "Running test: test_agentfarm_cleanup.sh"

# Create .agentfarm/dummy.txt
mkdir -p .agentfarm
echo "dummy" > .agentfarm/dummy.txt

# Assert the file exists
if [ ! -f ".agentfarm/dummy.txt" ]; then
    echo "FAIL: .agentfarm/dummy.txt was not created"
    exit 1
fi
echo "PASS: .agentfarm/dummy.txt created successfully"

# Assert that .agentfarm/ is ignored by git
if ! git check-ignore -q .agentfarm/dummy.txt; then
    echo "FAIL: .agentfarm/ is NOT ignored by git."
    echo "Expected .agentfarm/ to be in .gitignore"
    # Clean up the test artifact before exiting with failure
    rm -rf .agentfarm/
    exit 1
fi
echo "PASS: .agentfarm/ is ignored by git"

# Assert git status --porcelain does not show it
STATUS=$(git status --porcelain .agentfarm)
if [ -n "$STATUS" ]; then
    echo "FAIL: git status --porcelain shows .agentfarm files:"
    echo "$STATUS"
    rm -rf .agentfarm/
    exit 1
fi
echo "PASS: git status --porcelain does not show .agentfarm"

# Run the removal command (mocked based on requirements)
rm -rf .agentfarm/

# Assert the directory is gone
if [ -d ".agentfarm" ]; then
    echo "FAIL: .agentfarm/ directory was not removed"
    exit 1
fi
echo "PASS: .agentfarm/ directory was removed successfully"

echo "ALL TESTS PASSED."
