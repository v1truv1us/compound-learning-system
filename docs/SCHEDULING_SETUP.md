# Compound Learning System - Scheduling Setup

This document explains how to set up automated scheduling for both Claude and OpenCode compound systems.

## Quick Start

### Option 1: Automatic Cron Setup (Recommended)

From the ~/git directory, run:

```bash
# Setup Claude scheduling
./setup-claude-scheduling.sh

# Setup OpenCode scheduling
./opencode-compound/setup-multi-project-timers.sh

# Verify cron jobs were added
crontab -l | grep -E "claude|opencode|compound"
```

### Option 2: Manual Cron Setup

If automatic setup doesn't work, add these manually:

```bash
crontab -e
```

Then add these lines:

```cron
# Claude Compound Review - 11:00 PM daily
0 23 * * * cd /home/vitruvius/git && ./scripts/claude-compound-review.sh >> logs/claude-compound-review.log 2>&1

# Claude Auto-Compound - 11:30 PM daily
30 23 * * * cd /home/vitruvius/git && ./scripts/claude-auto-compound.sh >> logs/claude-auto-compound.log 2>&1

# OpenCode Compound Review - 10:30 PM daily
30 22 * * * cd /home/vitruvius/git && ./opencode-compound/scripts/opencode-multi-project-review.sh >> logs/opencode-compound-review.log 2>&1

# OpenCode Auto-Compound - 11:15 PM daily
15 23 * * * cd /home/vitruvius/git && ./opencode-compound/scripts/opencode-multi-project-auto-compound.sh >> logs/opencode-auto-compound.log 2>&1
```

Save with `Ctrl+X` then `Y` then `Enter`.

## Schedule Overview

The complete nightly automation sequence:

```
10:30 PM (22:30)  OpenCode Compound Review
   └─ Extract learnings → Update AGENTS.md → Commit
   └─ Send Discord notification

11:00 PM (23:00)  Claude Compound Review
   └─ Extract learnings → Update CLAUDE.md → Commit
   └─ Send Discord notification

11:15 PM (23:15)  OpenCode Auto-Compound
   └─ Pick priority from AGENTS.md → Implement → Create PR
   └─ Send Discord notification

11:30 PM (23:30)  Claude Auto-Compound
   └─ Pick priority from CLAUDE.md → Implement → Create PR
   └─ Send Discord notification
```

## Verification

### Check if cron jobs are scheduled

```bash
crontab -l
```

You should see 4 entries for compound and auto-compound.

### Check logs after runs

```bash
# Most recent Claude review
tail -20 logs/claude-compound-review.log

# Most recent OpenCode review
tail -20 logs/opencode-compound-review.log

# Most recent Claude implementation
tail -20 logs/claude-auto-compound.log

# Most recent OpenCode implementation
tail -20 logs/opencode-auto-compound.log
```

### Monitor Discord

Check your Discord webhook channel for notifications every evening. You should see:
- 10:30 PM: "OpenCode Compound Review Starting"
- 11:00 PM: "Claude Compound Review Starting"
- 11:15 PM: "OpenCode Auto-Compound Starting"
- 11:30 PM: "Claude Auto-Compound Starting"

## Manual Testing

### Test Claude system before scheduling

```bash
# Test compound review (extracts learnings)
./scripts/claude-compound-review.sh

# Test auto-compound (implements priorities)
./scripts/claude-auto-compound.sh
```

### Test OpenCode system before scheduling

```bash
# Test multi-project compound review
./opencode-compound/scripts/opencode-multi-project-review.sh

# Test multi-project auto-compound
./opencode-compound/scripts/opencode-multi-project-auto-compound.sh
```

### Test single project

```bash
# Claude: test on one project
./scripts/claude-compound-review.sh --project fleettools

# OpenCode: test on one project
./opencode-compound/scripts/opencode-multi-project-review.sh --project fleettools
```

## Troubleshooting

### Cron jobs not appearing in crontab -l

```bash
# Check if cron is running
sudo systemctl status cron

# Or on systems with crond
sudo systemctl status crond

# Check system logs for errors
sudo tail -50 /var/log/syslog | grep cron
```

### Scripts not executing at scheduled time

1. Check if Discord is receiving notifications:
   - Go to your Discord webhook channel
   - Look for log messages at scheduled times

2. Verify cron job syntax:
   ```bash
   crontab -l | grep compound
   ```
   Each line should have exactly 5 time fields and a command

3. Check script permissions:
   ```bash
   ls -la scripts/claude*.sh
   ls -la opencode-compound/scripts/opencode*.sh
   ```
   Should show `rwx--x--x` or similar executable permissions

### Discord notifications not arriving

1. Verify webhook URL:
   ```bash
   cat scripts/.env.local | grep DISCORD
   cat bin/.env.local | grep DISCORD
   ```

2. Test webhook manually:
   ```bash
   WEBHOOK_URL="..."
   curl -X POST "$WEBHOOK_URL" \
     -H 'Content-Type: application/json' \
     -d '{"embeds":[{"title":"Test","description":"Webhook works!","color":3066993}]}'
   ```

3. Check cron email for errors:
   ```bash
   # Some systems mail cron output to your user
   mail
   # Or check syslog
   grep CRON /var/log/syslog
   ```

## System Requirements

- **Bash** - For running shell scripts (usually pre-installed)
- **Claude Code CLI** - For Claude-based scripts: `npm install -g claude`
- **OpenCode CLI** - For OpenCode-based scripts
- **curl** - For Discord webhook notifications (usually pre-installed)
- **git** - For cloning and committing changes
- **cron** or **crond** - For scheduling (usually pre-installed)

## Additional Notes

- Both systems run **independently** - they won't interfere with each other
- Review runs (11:00 PM, 10:30 PM) should complete **before** auto-compound runs (11:30 PM, 11:15 PM)
- Check logs regularly to monitor system health
- Projects are skipped if they're not git repositories
- Network interruptions won't break the system - scripts handle errors gracefully

## Next Steps

1. ✅ Run manual test: `./scripts/claude-compound-review.sh`
2. ✅ Verify logs: `tail logs/claude-compound-review.log`
3. ✅ Check Discord notifications appear
4. ✅ Set up cron scheduling
5. ✅ Monitor for a few days to ensure it's working

Once verified, your compound learning system is ready to run while you sleep!
