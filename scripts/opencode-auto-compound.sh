#!/bin/bash
# opencode-auto-compound.sh - Implement priority with OpenCode

set -eEuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$GIT_ROOT/logs/opencode-auto-compound.log"
COMPOUND_ROOT="$SCRIPT_DIR/.."
REPORTS_DIR="$COMPOUND_ROOT/reports"
TASKS_DIR="$COMPOUND_ROOT/tasks"

mkdir -p "$GIT_ROOT/logs" "$REPORTS_DIR" "$TASKS_DIR"

{
  echo "=== OpenCode Auto-Compound Started: $START_TIMESTAMP ==="
  echo "Model: $OPENCODE_MODEL"
} | tee "$LOG_FILE"

send_discord "🚀 OpenCode Auto-Compound Starting" "Implementing priority improvements"

LATEST_REPORT=$(ls -t "$REPORTS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
  log "No reports found" | tee -a "$LOG_FILE"
  exit 0
fi

ANALYSIS=$("$SCRIPT_DIR/analyze-report.sh" "$LATEST_REPORT")
# Parse JSON - use python3 as fallback if jq not available
if command -v jq >/dev/null 2>&1; then
  PRIORITY_ITEM=$(echo "$ANALYSIS" | jq -r '.priority_item')
  BRANCH_NAME=$(echo "$ANALYSIS" | jq -r '.branch_name')
else
  PRIORITY_ITEM=$(echo "$ANALYSIS" | python3 -c "import sys, json; print(json.load(sys.stdin)['priority_item'])")
  BRANCH_NAME=$(echo "$ANALYSIS" | python3 -c "import sys, json; print(json.load(sys.stdin)['branch_name'])")
fi

cd "$GIT_ROOT" || exit 1

if ! git checkout -b "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
  log_error "Failed to create branch"
  exit 1
fi

log "Generating PRD and tasks for: $PRIORITY_ITEM" | tee -a "$LOG_FILE"

if ! timeout "$OPENCODE_TIMEOUT" opencode -p "
Load the prd skill and tasks skill

Create PRD for: $PRIORITY_ITEM
Save to: $TASKS_DIR/prd.json

Break into 3-6 atomic tasks with acceptance criteria.
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE"; then
  log_error "OpenCode PRD generation failed or timed out"
  git checkout - 2>/dev/null || true
  exit 1
fi

log "Executing with loop" | tee -a "$LOG_FILE"
if ! "$SCRIPT_DIR/loop.sh" 25 2>&1 | tee -a "$LOG_FILE"; then
  log_error "Loop execution failed"
  git checkout - 2>/dev/null || true
  exit 1
fi

if ! git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
  log_warning "Git push failed - branch created locally"
fi

send_discord "✅ OpenCode Auto-Compound Complete" "Implemented: $PRIORITY_ITEM" 3066993

exit 0
