# Compound Learning System Runbook

Purpose: 5-minute checks to confirm your nightly automation is healthy and receiving Discord notifications.

## Quick Health Checks (run anytime)

```bash
# 1. Is anything scheduled?
crontab -l | grep -E "claude|compound"
systemctl --user list-timers | grep -E "opencode|compound"

# 2. When was the last successful run?
ls -la /home/vitruvius/git/logs/
tail -n 20 /home/vitruvius/git/logs/claude-compound-review.log
tail -n 20 /home/vitruvius/git/logs/claude-auto-compound.log
journalctl --user -u opencode-multi-project-review.service -n 50 --no-pager
journalctl --user -u opencode-multi-project-auto-compound.service -n 50 --no-pager

# 3. Are any notifications arriving?
# Check your Discord channel for recent messages from the bot

# 4. Are configs aligned?
grep "DISCORD_WEBHOOK_URL" /home/vitruvius/.config/compound-learning/config.env
ls -la /home/vitruvius/.config/opencode-compound/environment.conf
```

## Common Failure Patterns

| Symptom | Likely Cause | Quick Fix |
|-----------|----------------|------------|
| No logs updated | Cron not running / wrong paths | Fix crontab paths, ensure log dirs exist |
| All jobs fail at `fatal: not a git repository` | Scripts running in wrong directory | Update systemd EnvironmentFile to correct repo root |
| Discord messages missing | Webhook mismatch / silently failing | Verify webhook URL in central config; test manually |
| “local: can only be used in a function” | Bash script syntax error | Fix script or add `shopt -s expand_aliases` |

## Manual Smoke Test (single project)

```bash
cd /home/vitruvius/git/compound-learning-system
./scripts/claude-compound-review.sh --project fleettools
```

- Expected: CLAUDE.md updated in fleettools
- Verify: `git -C /home/vitruvius/git/fleettools log -1 --oneline | grep "chore: compound learning"`
- Check Discord for “Claude Compound Review Starting/Complete” messages

## Scheduled Run Troubleshooting

### If Discord notifications stop arriving

1. Check scheduler status
   ```bash
   crontab -l
   systemctl --user list-timers
   ```

2. Check logs for failures
   ```bash
   tail -100 /home/vitruvius/git/logs/claude-compound-review.log | grep -i error
   journalctl --user -u opencode-multi-project-review.service -n 100 --no-pager | grep -i error
   ```

3. Verify configuration consistency
   ```bash
   # Ensure both systems use same Discord webhook
   grep "DISCORD_WEBHOOK_URL" /home/vitruvius/.config/compound-learning/config.env
   ```

4. Test webhook manually
   ```bash
   # Use the URL from the config (do NOT paste tokens here)
   curl -X POST "YOUR_DISCORD_WEBHOOK_URL" \
     -H 'Content-Type: application/json' \
     -d '{"embeds":[{"title":"Test","description":"If you see this, webhooks work","color":3066993}]}'
   ```

## Restoring Health After Issues

1. **Stop duplicate runs** to reduce noise
   ```bash
   # Disable problematic timers temporarily
   systemctl --user disable opencode-compound-review.timer opencode-auto-compound.timer
   # Or remove cron entries if using cron
   ```

2. **Clean up any failed branches** left by auto-compound
   ```bash
   cd /home/vitruvius/git
   git checkout main
   git branch -D compound-* 2>/dev/null || true
   ```

3. **Re-enable a single scheduler** once fixes are in place
   ```bash
   # Enable the corrected timer(s)
   systemctl --user enable --now opencode-multi-project-review.timer
   ```

## Expected “Healthy” Baseline

- Nightly logs update within scheduled window (22:30–23:30)
- Discord receives START and SUCCESS/FAILURE messages for each pipeline
- No “fatal: not a git repository” errors in any log
- All git operations happen inside real repositories, not `/home/vitruvius/git`
- No duplicate timer runs (only one of each type active)

## Configuration Files At A Glance

| System | Config Path | Purpose |
|--------|-------------|---------|
| Claude | `~/.config/compound-learning/config.env` | DISCORD_WEBHOOK_URL, GIT_ROOT, CLAUDE_MODEL |
| OpenCode | `~/.config/compound-learning/config.env` | Same file as Claude (after unification) |

If you see `~/.config/opencode-compound/environment.conf`, it should be removed after unification.