#!/bin/bash
# claude-auto-compound.sh - Implement priority work from reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$GIT_ROOT/logs/claude-auto-compound.log"
COMPOUND_ROOT="$SCRIPT_DIR/.."
REPORTS_DIR="$COMPOUND_ROOT/reports"
TASKS_DIR="$COMPOUND_ROOT/tasks"

mkdir -p "$GIT_ROOT/logs" "$REPORTS_DIR" "$TASKS_DIR"

{
  echo "=== Claude Auto-Compound Started: $START_TIMESTAMP ==="
  echo "Model: $CLAUDE_MODEL"
} | tee "$LOG_FILE"

send_discord "🚀 Claude Auto-Compound Starting" "Analyzing priorities and implementing improvements"

LATEST_REPORT=$(ls -t "$REPORTS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
  log "No priority reports found, creating example report" | tee -a "$LOG_FILE"
  echo "# Priority: Improve test coverage

Add more unit tests to increase coverage to 80%+" > "$REPORTS_DIR/default-priority.md"
  LATEST_REPORT="$REPORTS_DIR/default-priority.md"
fi

log "Using report: $(basename "$LATEST_REPORT")" | tee -a "$LOG_FILE"

# Parse report (analyze-report.sh outputs priority_item on line 1, branch_name on line 2)
ANALYSIS=$("$SCRIPT_DIR/analyze-report.sh" "$LATEST_REPORT")
PRIORITY_ITEM=$(echo "$ANALYSIS" | head -1)
BRANCH_NAME=$(echo "$ANALYSIS" | tail -1)

log "Priority: $PRIORITY_ITEM" | tee -a "$LOG_FILE"
log "Branch: $BRANCH_NAME" | tee -a "$LOG_FILE"

cd "$GIT_ROOT" || exit 1

if ! git checkout -b "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
  log_error "Failed to create branch" | tee -a "$LOG_FILE"
  exit 1
fi

log "Generating PRD for: $PRIORITY_ITEM" | tee -a "$LOG_FILE"
if ! timeout "$CLAUDE_TIMEOUT" claude -p "
Load the prd skill from $COMPOUND_ROOT/skills/prd.md

Create a comprehensive PRD for this priority item:
$PRIORITY_ITEM

Save the PRD to $TASKS_DIR/prd.json in JSON format.
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE"; then
  log_error "PRD generation failed" | tee -a "$LOG_FILE"
  git checkout - 2>/dev/null || true
  exit 1
fi

log "Converting PRD to tasks" | tee -a "$LOG_FILE"
if ! timeout "$CLAUDE_TIMEOUT" claude -p "
Load the tasks skill from $COMPOUND_ROOT/skills/tasks.md

Read the PRD from $TASKS_DIR/prd.json and break it into 3-6 atomic tasks.
Update the same file by adding a 'tasks' array.

Each task should:
- Have clear acceptance criteria
- Be completable in 5-15 minutes
- Include dependencies if needed
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE"; then
  log_error "Task breakdown failed" | tee -a "$LOG_FILE"
  git checkout - 2>/dev/null || true
  exit 1
fi

log "Executing task loop (max 25 iterations)" | tee -a "$LOG_FILE"
if "$SCRIPT_DIR/loop.sh" 25 2>&1 | tee -a "$LOG_FILE"; then
  log "✅ All tasks completed" | tee -a "$LOG_FILE"
else
  log "⚠️ Some tasks failed" | tee -a "$LOG_FILE"
fi

log "Creating pull request" | tee -a "$LOG_FILE"
if git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
  if command_exists gh; then
    gh pr create --draft --title "Compound: $PRIORITY_ITEM" --body "Auto-generated from compound learning system" 2>&1 | tee -a "$LOG_FILE" || true
    log "✅ PR created" | tee -a "$LOG_FILE"
  fi
fi

END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
send_discord "✅ Claude Auto-Compound Complete" "Implemented: $PRIORITY_ITEM on branch: $BRANCH_NAME" 3066993

log "=== Completed: $END_TIMESTAMP ===" | tee -a "$LOG_FILE"
exit 0
