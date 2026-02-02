# Scheduling Active ✅

Both Claude and OpenCode compound systems are now **scheduled and running automatically**.

## Current Schedule

### Claude System (Cron Jobs)
```
11:00 PM (23:00)  Claude Compound Review
  └─ Command: cd /home/vitruvius/git && ./scripts/claude-compound-review.sh
  └─ Log: logs/claude-compound-review.log
  └─ Cron: 0 23 * * *

11:30 PM (23:30)  Claude Auto-Compound
  └─ Command: cd /home/vitruvius/git && ./scripts/claude-auto-compound.sh
  └─ Log: logs/claude-auto-compound.log
  └─ Cron: 30 23 * * *
```

### OpenCode System (Systemd Timers)
```
10:30 PM (22:30)  OpenCode Multi-Project Review
  └─ Service: opencode-multi-project-review.service
  └─ Timer: opencode-multi-project-review.timer
  └─ Log: logs/opencode-compound-review.log

11:15 PM (23:15)  OpenCode Multi-Project Auto-Compound
  └─ Service: opencode-multi-project-auto-compound.service
  └─ Timer: opencode-multi-project-auto-compound.timer
  └─ Log: logs/opencode-auto-compound.log
```

## Complete Daily Automation Flow

```
10:30 PM  OpenCode Review     → Extract learnings, update AGENTS.md
11:00 PM  Claude Review       → Extract learnings, update CLAUDE.md
11:15 PM  OpenCode Auto       → Implement priority from AGENTS.md
11:30 PM  Claude Auto         → Implement priority from CLAUDE.md
```

All agents run **independently and in parallel** throughout the evening.

## Verify Scheduling Status

### Check Claude cron jobs
```bash
crontab -l | grep compound
```

Expected output:
```
0 23 * * * cd /home/vitruvius/git && ./scripts/claude-compound-review.sh >> /home/vitruvius/git/logs/claude-compound-review.log 2>&1 # Claude Compound Review
30 23 * * * cd /home/vitruvius/git && ./scripts/claude-auto-compound.sh >> /home/vitruvius/git/logs/claude-auto-compound.log 2>&1 # Claude Auto-Compound
```

### Check OpenCode systemd timers
```bash
systemctl --user list-timers | grep -E "opencode|compound"
```

Expected output shows both multi-project timers active with next run times.

### Check if services are active
```bash
systemctl --user status opencode-multi-project-review.timer
systemctl --user status opencode-multi-project-auto-compound.timer
```

## Monitoring

### Watch logs in real-time
```bash
# All compound logs
tail -f logs/claude-*.log logs/opencode-*.log

# Or just Claude
tail -f logs/claude-compound-review.log
tail -f logs/claude-auto-compound.log

# Or just OpenCode
tail -f logs/opencode-compound-review.log
tail -f logs/opencode-auto-compound.log
```

### Check for errors
```bash
# Find all errors
grep -i error logs/*.log

# Check specific run
tail -100 logs/claude-compound-review.log | grep -E "✅|❌|Error"
```

### Monitor Discord notifications
Your Discord webhook channel should receive notifications at:
- 10:30 PM - OpenCode review starting
- 11:00 PM - Claude review starting
- 11:15 PM - OpenCode implementation starting
- 11:30 PM - Claude implementation starting

Plus completion notifications when each finishes.

## Manual Testing

### Test Claude system manually
```bash
cd ~/git

# Run review manually
./scripts/claude-compound-review.sh

# Run implementation manually
./scripts/claude-auto-compound.sh

# Test single project
./scripts/claude-compound-review.sh --project fleettools
```

### Test OpenCode system manually
```bash
cd ~/git

# Run multi-project review
./opencode-compound/scripts/opencode-multi-project-review.sh

# Run multi-project auto-compound
./opencode-compound/scripts/opencode-multi-project-auto-compound.sh

# Test single project
./opencode-compound/scripts/opencode-multi-project-review.sh --project fleettools
```

## Modifying Schedule

### Change Claude schedule (cron)
```bash
# Edit cron jobs
crontab -e

# Find the two Claude compound lines and adjust times as needed
# Example: Change 11:00 PM (0 23) to 12:00 AM (0 0)
0 0 * * * cd /home/vitruvius/git && ./scripts/claude-compound-review.sh >> /home/vitruvius/git/logs/claude-compound-review.log 2>&1
30 0 * * * cd /home/vitruvius/git && ./scripts/claude-auto-compound.sh >> /home/vitruvius/git/logs/claude-auto-compound.log 2>&1

# Save and exit
```

### Change OpenCode schedule (systemd)
```bash
# Edit the timer files
systemctl --user edit opencode-multi-project-review.timer
systemctl --user edit opencode-multi-project-auto-compound.timer

# Modify OnCalendar= lines (cron format)
# Reload and restart
systemctl --user daemon-reload
systemctl --user restart opencode-multi-project-review.timer
systemctl --user restart opencode-multi-project-auto-compound.timer
```

## Disable Scheduling

### Disable Claude (cron)
```bash
# Remove from crontab
crontab -e
# Delete the two Claude compound lines
```

### Disable OpenCode (systemd)
```bash
# Stop and disable timers
systemctl --user stop opencode-multi-project-review.timer
systemctl --user stop opencode-multi-project-auto-compound.timer
systemctl --user disable opencode-multi-project-review.timer
systemctl --user disable opencode-multi-project-auto-compound.timer
```

## Troubleshooting

### Claude jobs not running
1. Verify cron is active: `systemctl status cron`
2. Check job syntax: `crontab -l`
3. View system logs: `grep CRON /var/log/syslog | tail -20`
4. Test manually: `./scripts/claude-compound-review.sh`

### OpenCode jobs not running
1. Check timer status: `systemctl --user status opencode-multi-project-review.timer`
2. View timer logs: `journalctl --user -u opencode-multi-project-review.timer -n 20`
3. Test manually: `./opencode-compound/scripts/opencode-multi-project-review.sh`

### Discord notifications not arriving
1. Check webhook URL: `grep DISCORD scripts/.env.local`
2. Test webhook:
   ```bash
   source scripts/.env.local
   curl -X POST "$DISCORD_WEBHOOK_URL" \
     -H 'Content-Type: application/json' \
     -d '{"embeds":[{"title":"Test","description":"Works!","color":3066993}]}'
   ```
3. Check script logs for webhook sending errors

### Scripts timing out
- Increase timeout in scripts if needed
- Check available system resources during run time
- Consider running fewer projects or at different times

## Success Indicators

You'll know everything is working when:

✅ Cron jobs appear in `crontab -l`
✅ Systemd timers appear in `systemctl --user list-timers`
✅ Discord notifications arrive at scheduled times
✅ Log files are updated after each run
✅ CLAUDE.md and AGENTS.md files update with learnings
✅ New commits appear with "chore: compound learning" messages
✅ PRs are created for implemented work

## System Status

```
Claude System:      ✅ SCHEDULED (Cron)
OpenCode System:    ✅ SCHEDULED (Systemd)
Discord Webhook:    ✅ CONFIGURED
Logs Directory:     ✅ READY
All Projects:       ✅ DISCOVERABLE
```

## Next Steps

1. **Wait for first run** - Tonight at 10:30 PM (OpenCode starts first)
2. **Monitor logs** - Check logs directory after each scheduled run
3. **Watch Discord** - Verify notifications arrive at scheduled times
4. **Review updates** - Check CLAUDE.md and AGENTS.md files for learnings
5. **Observe patterns** - Watch how each day's learnings inform the next

Your compound learning system is now **fully active and ready to learn while you sleep!**

---

**Activated:** January 30, 2026
**Status:** ✅ Running and Monitoring
**Next Run:** 10:30 PM Tonight (OpenCode Review)
