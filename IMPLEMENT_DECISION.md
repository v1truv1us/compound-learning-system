# Implementation Decision: Discord Webhook Unification

## Decision
- Use the existing Discord webhook from Claude's config (`~/.config/compound-learning/config.env`) as the single source of truth for both systems.

## Rationale
- It's already working for Claude's test runs.
- Avoids creating a new webhook/channel; minimal disruption.
- Centralizes credential management in one file.

## Implementation Steps
1. Update OpenCode systemd services to use `EnvironmentFile=%h/.config/compound-learning/config.env`
2. Remove the separate `~/.config/opencode-compound/environment.conf` file
3. Verify OpenCode Claude tool loads DISCORD_WEBHOOK_URL from that shared file
4. Test by running a single OpenCode review and confirming the notification arrives in the same Discord channel as Claude notifications

## Files to Update
- `~/.config/systemd/user/opencode-*.service` (change EnvironmentFile line)
- Remove `~/.config/opencode-compound/environment.conf`
- Optionally document this in `docs/RUNBOOK.md`