#!/bin/bash
# common.sh - Shared functions for compound learning system
# Sourced by all scripts for consistent config loading and utilities

# Load central configuration
load_config() {
  local CONFIG_FILE="$HOME/.config/compound-learning/config.env"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    echo "Please run ./setup.sh to configure the compound learning system"
    exit 1
  fi

  # Source the config file
  source "$CONFIG_FILE"

  # Validate required variables
  if [ -z "$GIT_ROOT" ]; then
    echo "ERROR: GIT_ROOT not set in config"
    exit 1
  fi

  # Set defaults for optional variables
  CLAUDE_MODEL="${CLAUDE_MODEL:-claude-opus-4-5}"
  OPENCODE_MODEL="${OPENCODE_MODEL:-opencode-default}"
  CLAUDE_TIMEOUT="${CLAUDE_TIMEOUT:-600}"
  OPENCODE_TIMEOUT="${OPENCODE_TIMEOUT:-600}"
}

# Send Discord notification
# Usage: send_discord "Title" "Description" [color]
send_discord() {
  local title="$1"
  local description="$2"
  local color="${3:-3447003}"  # Default: blue

  # Skip if webhook not configured
  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    return 0
  fi

  # Build JSON payload
  local payload=$(cat <<EOF
{
  "embeds": [{
    "title": "$title",
    "description": "$description",
    "color": $color,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }]
}
EOF
)

  # Send to Discord (silently fail if webhook is down)
  curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$payload" >/dev/null 2>&1 || true
}

# Detect platform
# Returns: "macos", "linux", or "unknown"
detect_platform() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Get script directory (useful for finding relative paths)
get_script_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# Get compound learning system root
get_compound_root() {
  local script_dir=$(get_script_dir)
  echo "$(dirname "$script_dir")"
}

# Log with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Log error with timestamp
log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Ensure required commands are available
require_commands() {
  local missing=()

  for cmd in "$@"; do
    if ! command_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required commands: ${missing[*]}"
    exit 1
  fi
}

# Git operations with error handling
git_safe() {
  if ! git "$@" 2>&1; then
    log_error "Git command failed: git $*"
    return 1
  fi
  return 0
}

# Functions are available to callers when common.sh is sourced
