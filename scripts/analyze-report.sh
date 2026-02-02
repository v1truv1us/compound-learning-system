#!/bin/bash
# analyze-report.sh - Parse priority reports and extract actionable items
# Outputs JSON with priority item and generated branch name

set -e

REPORT_FILE="$1"

if [ -z "$REPORT_FILE" ] || [ ! -f "$REPORT_FILE" ]; then
  echo "Usage: analyze-report.sh <report-file>"
  exit 1
fi

# Extract priority item (first line with priority/feature/implement)
PRIORITY_ITEM=$(grep -i "priority\|feature\|implement" "$REPORT_FILE" | head -1 | sed 's/^[#-]*\s*//' | sed 's/[[:space:]]*$//')

if [ -z "$PRIORITY_ITEM" ]; then
  # Fallback: use first non-empty line
  PRIORITY_ITEM=$(grep -v '^[[:space:]]*$' "$REPORT_FILE" | head -1 | sed 's/^[#-]*\s*//' | sed 's/[[:space:]]*$//')
fi

# Generate branch name from priority item
# Convert to lowercase, replace spaces with hyphens, remove special chars
BRANCH_NAME=$(echo "$PRIORITY_ITEM" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | sed 's/[[:space:]]\+/-/g' | cut -c1-50)

# Add timestamp to ensure uniqueness
BRANCH_NAME="compound-${BRANCH_NAME}-$(date +%s)"

# Output shell-compatible format (one per line)
echo "$PRIORITY_ITEM"
echo "$BRANCH_NAME"
