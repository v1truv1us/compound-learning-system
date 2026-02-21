#!/bin/bash
# opencode-compound-review.sh - Extract learnings with OpenCode

set -eEuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_config

START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$GIT_ROOT/logs/opencode-compound-review.log"
COMPOUND_ROOT="$SCRIPT_DIR/.."

mkdir -p "$GIT_ROOT/logs"

{
  echo "=== OpenCode Compound Review Started: $START_TIMESTAMP ==="
  echo "Model: $OPENCODE_MODEL"
} | tee "$LOG_FILE"

send_discord "🔄 OpenCode Compound Review Starting" "Extracting learnings across projects"

success_count=0
total_count=0

for project_dir in "$GIT_ROOT"/*; do
  if [ -d "$project_dir/.git" ] 2>/dev/null; then
    project_name=$(basename "$project_dir")

    case "$project_name" in
      compound-learning-system|node_modules|.git|.local|logs|docs|plans|scripts|bin)
        continue
        ;;
    esac

    total_count=$((total_count + 1))
    cd "$project_dir" || continue

    log "Analyzing $project_name" | tee -a "$LOG_FILE"

    if timeout "$OPENCODE_TIMEOUT" opencode -p "
Load the compound-engineering skill

Review recent git history and extract learnings.
Update CLAUDE.md with new patterns discovered (APPEND ONLY).
Commit with: 'chore: compound learning from opencode'
" --allowedTools "Bash,Read,Edit,Bash(git *)" --max-turns 10 2>&1 | tee -a "$LOG_FILE"; then
      success_count=$((success_count + 1))
      log "✅ $project_name analyzed" | tee -a "$LOG_FILE"
    else
      log "⚠️ $project_name analysis failed" | tee -a "$LOG_FILE"
    fi
  fi
done

{
  echo ""
  echo "=== Summary ==="
  echo "Projects Analyzed: $success_count/$total_count"
  echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
} | tee -a "$LOG_FILE"

send_discord "✅ OpenCode Compound Review Complete" "Analyzed $success_count/$total_count projects" 3066993

exit 0
