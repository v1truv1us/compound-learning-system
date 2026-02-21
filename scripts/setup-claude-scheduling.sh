#!/bin/bash
# setup-claude-scheduling.sh
# Sets up cron jobs for Claude compound review and auto-compound
# Schedule:
#   11:00 PM Daily: Claude Compound Review (extracts learnings from all projects)
#   11:30 PM Daily: Claude Auto-Compound (implements priority work in all projects)

set -eEuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Setting up Claude compound scheduling..."
echo "Git Root: $GIT_ROOT"

# Function to add cron job
add_cron_job() {
  local schedule="$1"
  local command="$2"
  local description="$3"

  # Check if job already exists
  if crontab -l 2>/dev/null | grep -F -q -- "$command"; then
    echo "⚠️  Cron job already exists for: $description"
    return 0
  fi

  # Add new job
  (crontab -l 2>/dev/null || echo ""; echo "$schedule $command # $description") | crontab -
  echo "✅ Added cron job: $description"
  echo "   Schedule: $schedule"
  echo "   Command: $command"
}

# Setup cron jobs
echo ""
echo "=== Claude Compound Review ==="
echo "Time: 11:00 PM (23:00)"
add_cron_job \
  "0 23 * * *" \
  "flock -n /tmp/claude-compound-review.lock -c \"cd \\\"$GIT_ROOT\\\" && ./scripts/claude-compound-review.sh >> \\\"$GIT_ROOT/logs/claude-compound-review.log\\\" 2>&1\"" \
  "Claude Compound Review"

echo ""
echo "=== Claude Auto-Compound ==="
echo "Time: 11:30 PM (23:30)"
add_cron_job \
  "30 23 * * *" \
  "flock -n /tmp/claude-auto-compound.lock -c \"cd \\\"$GIT_ROOT\\\" && ./scripts/claude-auto-compound.sh >> \\\"$GIT_ROOT/logs/claude-auto-compound.log\\\" 2>&1\"" \
  "Claude Auto-Compound"

echo ""
echo "=== Current Cron Jobs ==="
crontab -l 2>/dev/null | grep -E "claude|compound" || echo "No Claude scheduling jobs found"

echo ""
echo "✅ Claude scheduling setup complete!"
echo ""
echo "To remove these jobs later, run: crontab -e"
