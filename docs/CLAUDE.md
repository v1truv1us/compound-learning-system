# Claude Compound Learning System

This document describes the dual-agent compound learning system for the ~/git/ ecosystem. The system runs **both Claude Code and OpenCode** in a nightly loop where agents review projects, extract learnings, and implement priority work - creating a self-improving codebase.

## Overview

The compound learning system has two halves:

### 1. **Claude Code Compound** (Claude-based agents)
- Extracts learnings using Claude Opus 4.5
- Updates CLAUDE.md files across all projects
- Implements priority work identified in CLAUDE.md
- Runs via CLI: `claude run "..."`

### 2. **OpenCode Compound** (OpenCode-based agents)
- Extracts learnings using OpenCode LLM
- Updates AGENTS.md files across all projects
- Implements priority work identified in AGENTS.md
- Uses multi-project review system

## Daily Schedule

```
11:00 PM  Claude Compound Review  → Extracts learnings, updates CLAUDE.md
11:15 PM  OpenCode Compound Review → Extracts learnings, updates AGENTS.md
11:30 PM  Claude Auto-Compound     → Implements priorities from CLAUDE.md
12:00 AM  OpenCode Auto-Compound   → Implements priorities from AGENTS.md
```

The **review steps must run BEFORE implementation steps** so agents benefit from fresh learnings.

## Directory Structure

```
~/git/
├── scripts/
│   ├── claude-compound-review.sh          # Claude review loop (all projects)
│   ├── claude-auto-compound.sh            # Claude implementation loop
│   ├── opencode-compound-review.sh        # → opencode-compound/scripts/
│   └── opencode-auto-compound.sh          # → opencode-compound/scripts/
├── bin/
│   ├── claude-compound-review             # Symlink to scripts/
│   ├── claude-auto-compound               # Symlink to scripts/
│   ├── opencode-compound-review           # → opencode-compound/bin/
│   └── opencode-auto-compound             # → opencode-compound/bin/
├── logs/
│   ├── claude-compound-review.log         # Claude review output
│   ├── claude-auto-compound.log           # Claude implementation output
│   ├── opencode-compound-review.log       # OpenCode review output
│   └── opencode-auto-compound.log         # OpenCode implementation output
├── ~/.config/compound-learning/config.env # Environment variables for both systems
├── setup-claude-scheduling.sh             # Cron job setup for Claude
├── opencode-compound/
│   ├── setup-multi-project-timers.sh      # Cron job setup for OpenCode
│   └── scripts/                           # OpenCode implementation
└── [projects]/
    ├── CLAUDE.md                          # Claude-managed project memory
    └── AGENTS.md                          # OpenCode-managed project memory
```

## Environment Configuration

### Discord Webhook Setup

Both systems require a Discord webhook URL for notifications:

```bash
# In ~/.config/compound-learning/config.env:
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"
CLAUDE_MODEL="claude-opus-4-5"
OPENCODE_MODEL="opencode/big-bucket"
```

Get your webhook URL:
1. Create a private Discord server
2. Right-click channel → Edit channel → Integrations → Webhooks → New Webhook
3. Copy the webhook URL
4. Add to central config file

### Quick Setup

```bash
# Create config directory and add webhook
mkdir -p ~/.config/compound-learning
echo 'DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."' >> ~/.config/compound-learning/config.env
```

## Usage

### Manual Runs

**Claude System:**
```bash
# Review all projects, extract learnings
./scripts/claude-compound-review.sh

# Implement priority work from CLAUDE.md
./scripts/claude-auto-compound.sh

# Review single project
./scripts/claude-compound-review.sh --project ai-eng-system
```

**OpenCode System:**
```bash
# Review all projects (multi-project mode)
./opencode-compound/scripts/opencode-multi-project-review.sh

# Auto-implement from reports
./opencode-compound/scripts/opencode-multi-project-auto-compound.sh

# Review single project
./opencode-compound/scripts/opencode-multi-project-review.sh --project ai-eng-system
```

### Automated Scheduling

**Setup Claude scheduling (cron):**
```bash
./setup-claude-scheduling.sh
```

This adds:
- 11:00 PM: Claude Compound Review
- 11:30 PM: Claude Auto-Compound

**Setup OpenCode scheduling (cron):**
```bash
./opencode-compound/setup-multi-project-timers.sh
```

This adds:
- 10:30 PM: OpenCode Compound Review
- 11:15 PM: OpenCode Auto-Compound

**Verify scheduling:**
```bash
crontab -l | grep -E "claude|opencode|compound"
```

## How It Works

### Phase 1: Compound Review (Extracts Learnings)

Both systems loop through **all projects** in ~/git/ and:

1. ✅ Analyze recent git history (last 10 commits)
2. ✅ Read existing CLAUDE.md / AGENTS.md files
3. ✅ Identify patterns, best practices, gotchas
4. ✅ Extract key learnings (3-5 bullet points)
5. ✅ Update the project's memory file
6. ✅ Commit with message: `chore: compound learning from session`
7. ✅ Send Discord notification with results

**Claude extracts learnings into CLAUDE.md:**
```markdown
## Recent Learnings

- Pattern discovered: Use error boundaries for async operations
- Gotcha: Discord webhook URL must be loaded before scripts start
- Solution: Store secrets in .env.local, not hardcoded
```

**OpenCode extracts learnings into AGENTS.md:**
```markdown
## Agent Patterns

- When implementing features, always check CLAUDE.md first for context
- Compound review must run before auto-compound for fresh learnings
- Use Discord notifications to track automation success
```

### Phase 2: Auto-Compound (Implements Work)

Both systems loop through all projects and:

1. ✅ Fetch latest from origin
2. ✅ Check CLAUDE.md / AGENTS.md for priority markers
3. ✅ Identify highest-impact improvement for each project
4. ✅ Implement the feature/fix using the agent
5. ✅ Update CLAUDE.md / AGENTS.md with the change
6. ✅ Create PR or commit
7. ✅ Send Discord notification

**Example: Claude implements a priority:**
```bash
claude run "
Review this project's CLAUDE.md and identify the top priority.
Implement a fix or feature for that priority.
Update CLAUDE.md and commit with 'feat: priority implementation from auto-compound'
"
```

## Learning Flow

The compound effect works because:

1. **Monday 11:00 PM** → Claude reviews projects, finds patterns → updates CLAUDE.md
2. **Monday 11:30 PM** → Claude reads fresh CLAUDE.md → implements with better context
3. **Tuesday 11:00 PM** → Claude reviews again, finds new patterns → updates CLAUDE.md again
4. **Tuesday 11:30 PM** → Claude benefits from yesterday's learnings

Each day the agents learn from the previous day's work, making their implementations progressively better.

## Comparing Systems

### Claude vs OpenCode

| Aspect | Claude | OpenCode |
|--------|--------|----------|
| **Agent Model** | Claude Opus 4.5 | OpenCode's LLM |
| **Memory File** | CLAUDE.md | AGENTS.md |
| **Invocation** | `claude run "..."` | `opencode` CLI |
| **Best For** | Complex reasoning, detailed learnings | Quick iterations, multi-project patterns |
| **Strength** | Deep analysis, comprehensive updates | Rapid implementation, pattern detection |

Both systems run **independently and in parallel** - they don't interfere with each other. Run whichever provides better results for your workflow, or run both for comparison.

## Monitoring

### View Recent Logs

```bash
# Claude review results
tail -f logs/claude-compound-review.log

# OpenCode review results
tail -f logs/opencode-compound-review.log

# Claude implementation
tail -f logs/claude-auto-compound.log

# OpenCode implementation
tail -f logs/opencode-auto-compound.log
```

### Check Discord Notifications

Both systems send real-time updates to Discord:
- ✅ Review starting (🔄)
- ✅ Review complete (✅)
- ⚠️  Failures or partial completions (⚠️)

### Debug Single Project

```bash
# Test Claude on one project
./scripts/claude-compound-review.sh --project fleettools

# Test OpenCode on one project
./opencode-compound/scripts/opencode-multi-project-review.sh --project fleettools
```

## Project-Level CLAUDE.md

Each project should have its own CLAUDE.md documenting:

```markdown
# Project: fleettools

## Current Focus
[What are we working on?]

## Recent Learnings
[Extracted by compound review]

## Gotchas
[Common mistakes found]

## Next Priority
[What should auto-compound implement?]
```

**Link to this system:**
```markdown
See also: [Root CLAUDE.md](../CLAUDE.md) for the compound learning system overview.
```

## Troubleshooting

### Discord notifications not appearing
```bash
# Check webhook URL is set
grep DISCORD_WEBHOOK_URL ~/.config/compound-learning/config.env

# Test webhook manually
curl -X POST "YOUR_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"embeds":[{"title":"Test","description":"Works!","color":3066993}]}'
```

### Scripts not running on schedule
```bash
# Verify cron is running
crontab -l

# Check logs for errors
grep -i error logs/claude-*.log logs/opencode-*.log

# Manually run to debug
./scripts/claude-compound-review.sh
```

### Claude Code not found
```bash
# Install Claude Code
npm install -g claude

# Verify installation
which claude
claude --version
```

## Next Steps

1. ✅ Set up Discord webhook URL in `~/.config/compound-learning/config.env`
2. ✅ Run manual test: `./scripts/claude-compound-review.sh`
3. ✅ Check logs and Discord for results
4. ✅ Run scheduling setup: `./setup-claude-scheduling.sh`
5. ✅ Verify cron jobs: `crontab -l`

The system is now ready to learn and ship while you sleep.

---

**Based on:** Ryan Carson's "How to make your agent learn and ship while you sleep"
**Systems:** Claude Code + OpenCode dual-agent compound learning
**Schedule:** Nightly 11:00 PM - 12:00 AM
