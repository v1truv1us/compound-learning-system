#!/bin/bash
# claude-compound-review.sh - Extract learnings from all projects
# Part 1 of the compound learning system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
START_EPOCH=$(date +%s)
LOG_FILE="$GIT_ROOT/logs/claude-compound-review.log"
COMPOUND_ROOT="$SCRIPT_DIR/.."

mkdir -p "$GIT_ROOT/logs"

{
  echo "=== Claude Compound Review Started: $START_TIMESTAMP ==="
  echo "Git Root: $GIT_ROOT"
  echo "Model: $CLAUDE_MODEL"
  echo "Project Mode: All Projects"
} | tee "$LOG_FILE"

send_discord "🔄 Claude Compound Review Starting" "Analyzing projects in $GIT_ROOT for patterns and learnings"

review_project() {
  local project_path="$1"
  local project_name=$(basename "$project_path")

  log "Reviewing $project_name" | tee -a "$LOG_FILE"

  if ! command_exists claude; then
    log_error "Claude Code not installed, skipping $project_name" | tee -a "$LOG_FILE"
    return 1
  fi

  cd "$project_path" || return 1

  if timeout "$CLAUDE_TIMEOUT" claude -p "
Load the compound-engineering skill from $COMPOUND_ROOT/skills/compound-engineering.md

Your task:
1. Review recent git history (last 10 commits)
2. Read existing CLAUDE.md and AGENTS.md if they exist
3. Extract 3-5 key learnings
4. Update CLAUDE.md with new learnings (APPEND ONLY - never overwrite)
5. Commit with: 'chore: compound learning from session'
6. Push to origin

Remember: All updates must APPEND to existing files. Use date format: YYYY-MM-DD: [learning]
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE"; then
    log "✅ $project_name: Learning extracted" | tee -a "$LOG_FILE"
    return 0
  else
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
      log_error "$project_name: TIMEOUT after ${CLAUDE_TIMEOUT}s" | tee -a "$LOG_FILE"
    else
      log_error "$project_name: Claude command failed" | tee -a "$LOG_FILE"
    fi
    return 1
  fi
}

success_count=0
total_count=0
failed_projects=""

SINGLE_PROJECT="${1#--project }"
if [ -n "$SINGLE_PROJECT" ] && [ "$SINGLE_PROJECT" != "$1" ]; then
  if [ -d "$GIT_ROOT/$SINGLE_PROJECT/.git" ]; then
    if review_project "$GIT_ROOT/$SINGLE_PROJECT"; then
      success_count=1
      total_count=1
    else
      failed_projects="$SINGLE_PROJECT"
      total_count=1
    fi
  else
    log_error "Project not found or not a git repo: $SINGLE_PROJECT"
    exit 1
  fi
else
  for project_dir in "$GIT_ROOT"/*; do
    if [ -d "$project_dir/.git" ] 2>/dev/null; then
      project_name=$(basename "$project_dir")

      case "$project_name" in
        compound-learning-system|node_modules|.git|.local|.opencode|.systemd|.claude|logs|docs|plans|scripts|bin|plugins)
          continue
          ;;
      esac

      total_count=$((total_count + 1))

      if review_project "$project_dir"; then
        success_count=$((success_count + 1))
      else
        failed_projects="$failed_projects $project_name"
      fi

      cd "$GIT_ROOT" || exit 1
    fi
  done
fi

END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

{
  echo ""
  echo "=== Summary ==="
  echo "Projects Reviewed: $success_count/$total_count"
  echo "Duration: ${DURATION}s"
  echo "Completed: $END_TIMESTAMP"
  if [ -n "$failed_projects" ]; then
    echo "Failed Projects:$failed_projects"
  fi
} | tee -a "$LOG_FILE"

if [ $success_count -eq $total_count ] && [ $total_count -gt 0 ]; then
  send_discord "✅ Claude Compound Review Complete" "Successfully reviewed all $total_count projects and updated CLAUDE.md files" 3066993
else
  failed_count=$((total_count - success_count))
  send_discord "⚠️ Claude Compound Review Partial" "Reviewed $success_count/$total_count projects ($failed_count failed)$failed_projects" 15105570
fi

exit 0
