# Compound Learning System

A self-improving agent automation system that extracts learnings from your projects and implements improvements nightly.

**Based on:** Ryan Carson's "How to make your agent learn and ship while you sleep"

## Overview

The system runs a two-phase loop every night:

1. **Compound Review (11:00 PM)** - Extract learnings
   - Analyzes recent git history across all projects
   - Identifies patterns, gotchas, best practices
   - Updates CLAUDE.md files with new learnings

2. **Auto-Compound (11:30 PM)** - Implement improvements
   - Reads priority reports
   - Generates PRDs using the prd skill
   - Breaks PRDs into atomic tasks
   - Executes tasks iteratively
   - Creates draft PRs

## Quick Start

### Initial Setup (Linux or Mac)

```bash
cd ~/git/compound-learning-system
./setup.sh
```

This will:
- Create central config at ~/.config/compound-learning/config.env
- Install cron jobs (Linux) or launchd plists (Mac)
- Make scripts executable

### Configuration

Edit ~/.config/compound-learning/config.env and add your Discord webhook URL:

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"
```

Leave empty to disable notifications.

### Test Manually

```bash
# Test learning extraction on a single project
./scripts/claude-compound-review.sh --project ai-eng-system

# Test auto-compound (creates tasks/prd.json)
./scripts/claude-auto-compound.sh
```

## Architecture

### Skills (The Ryan Carson Pattern)

- **compound-engineering.md** - Extract learnings from git history
- **prd.md** - Create structured PRDs from priority items
- **tasks.md** - Break PRDs into atomic executable tasks

### Execution Flow

1. Load compound-engineering skill → review projects → update CLAUDE.md
2. Load prd skill → create PRD from priority report
3. Load tasks skill → break PRD into 3-6 tasks
4. Run loop.sh → execute each task iteratively

## Files

- `setup.sh` - Cross-platform setup (cron or launchd)
- `scripts/common.sh` - Shared config and utilities
- `scripts/claude-compound-review.sh` - Learning extraction
- `scripts/claude-auto-compound.sh` - Priority implementation
- `scripts/opencode-*.sh` - OpenCode versions
- `scripts/analyze-report.sh` - Parse priority reports
- `scripts/loop.sh` - Iterative execution engine

## Configuration

Central config: ~/.config/compound-learning/config.env

```bash
DISCORD_WEBHOOK_URL=""          # Optional Discord notifications
CLAUDE_MODEL="claude-opus-4-5"  # Claude model
GIT_ROOT="$HOME/git"            # Projects root directory
```

## Scheduling

### Linux
```bash
0 23 * * * ~/git/compound-learning-system/scripts/claude-compound-review.sh
30 23 * * * ~/git/compound-learning-system/scripts/claude-auto-compound.sh
```

### Mac
Launchd plists installed at ~/Library/LaunchAgents/com.compound.*.plist

## Logs

Check execution at:
- ~/git/logs/claude-compound-review.log
- ~/git/logs/claude-auto-compound.log
- ~/git/logs/loop-execution.log

## Priority Reports

Create reports in reports/ directory:

```markdown
# Priority: Improve test coverage

Add unit tests to reach 80% coverage.
```

The system will:
1. Parse priority
2. Generate PRD
3. Create tasks
4. Execute iteratively
5. Create draft PR

## Troubleshooting

- **Config not found**: Run ./setup.sh
- **Claude not found**: npm install -g claude
- **Permission denied**: chmod +x scripts/*.sh
- **Discord not working**: Check webhook URL in config

See README for full documentation.
