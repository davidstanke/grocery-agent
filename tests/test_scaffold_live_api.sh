#!/usr/bin/env bash
set -e

echo "Running tests for Live API Agent scaffold..."

# 1. Check if agents/live-api-agent directory exists
if [ ! -d "agents/live-api-agent" ]; then
  echo "FAIL: Directory agents/live-api-agent does not exist."
  exit 1
fi

# 2. Check for critical ADK files
if [ ! -f "agents/live-api-agent/app/agent.py" ]; then
  echo "FAIL: File agents/live-api-agent/app/agent.py does not exist."
  exit 1
fi

if [ ! -f "agents/live-api-agent/pyproject.toml" ]; then
  echo "FAIL: File agents/live-api-agent/pyproject.toml does not exist."
  exit 1
fi

if [ ! -f "agents/live-api-agent/Makefile" ]; then
  echo "FAIL: File agents/live-api-agent/Makefile does not exist."
  exit 1
fi

# 3. Check for [tool.agents-cli] in pyproject.toml
if ! grep -q "\[tool.agents-cli\]" "agents/live-api-agent/pyproject.toml"; then
  echo "FAIL: [tool.agents-cli] not found in agents/live-api-agent/pyproject.toml."
  exit 1
fi

echo "PASS: All Live API Agent scaffold checks passed."
exit 0
