#!/bin/bash
# opencode-auto-compound.sh - Implement priority with OpenCode

set -e

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
PRIORITY_ITEM=$(echo "$ANALYSIS" | jq -r '.priority_item')
BRANCH_NAME=$(echo "$ANALYSIS" | jq -r '.branch_name')

cd "$GIT_ROOT" || exit 1

git checkout -b "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"

log "Generating PRD and tasks for: $PRIORITY_ITEM" | tee -a "$LOG_FILE"

timeout "$OPENCODE_TIMEOUT" opencode -p "
Load the prd skill and tasks skill

Create PRD for: $PRIORITY_ITEM
Save to: $TASKS_DIR/prd.json

Break into 3-6 atomic tasks with acceptance criteria.
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE" || true

log "Executing with loop" | tee -a "$LOG_FILE"
"$SCRIPT_DIR/loop.sh" 25 2>&1 | tee -a "$LOG_FILE" || true

git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE" || true

send_discord "✅ OpenCode Auto-Compound Complete" "Implemented: $PRIORITY_ITEM" 3066993

exit 0
