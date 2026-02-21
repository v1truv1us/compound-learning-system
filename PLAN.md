# Project Review Plan: compound-learning-system

## Goals
- Verify automation is actually running nightly (Claude + OpenCode) and producing outputs.
- Explain why Discord notifications have stopped and restore observability.
- Identify where “learnings” land (CLAUDE.md / AGENTS.md) and confirm they persist (committed/pushed).
- Produce a prioritized remediation list and (if desired) implement fixes.

## Output Artifacts (What You Get At The End)
- Clear status: last successful run per pipeline (Claude review / Claude auto / OpenCode review / OpenCode auto).
- One canonical scheduler (cron or systemd) with predictable logs and no duplicate runs.
- Discord notifications that are observable (success + failure + heartbeat).
- A short runbook: how to check, how to debug, and what “healthy” looks like.

## Architecture Map (What Runs What)

Actual (today):
- Setup: `setup.sh` -> `setup.ts` -> writes `~/.config/compound-learning/config.env`.
- Claude scheduling: user `crontab` entries (currently malformed).
- OpenCode scheduling: systemd user timers/services under `~/.config/systemd/user/`.
- Logs:
  - Claude logs: `/home/vitruvius/git/logs/claude-*.log`
  - OpenCode logs: `/home/vitruvius/git/logs/opencode-*.log` + systemd journal
  - Task loop log: `/home/vitruvius/git/compound-learning-system/logs/loop-execution.log`

Intended:
- Nightly review step writes learnings to each project’s `CLAUDE.md` / `AGENTS.md` and commits/pushes.
- Nightly auto-compound reads priorities and implements on a branch, then pushes/creates draft PR.

## Current Findings (Read-Only Audit, 2026-02-03)
- Claude scheduling (cron) is installed but appears broken:
  - Cron commands `cd` into `.../compound-learning-system/scripts` and then run `./scripts/...` (likely resolves to `scripts/scripts/...`).
  - Log redirection points at a non-existent `.../compound-learning-system/scripts/logs/` directory; shell redirection fails before the script starts.
  - Net: Claude nightly runs likely never execute, so no Discord notifications.
- systemd user timers for OpenCode are enabled and firing on schedule, but jobs fail fast with `fatal: not a git repository (or any of the parent directories): .git`.
- OpenCode multi-project scripts show additional bash errors (`local: can only be used in a function`) and attempt to run `git` in `.`.
- Several scripts can claim success even when a key command failed because `set -o pipefail` is missing and outputs are piped into `tee`.
- `scripts/claude-auto-compound.sh` runs `git checkout -b ...` inside `$GIT_ROOT` (configured to `/home/vitruvius/git`, not a git repo), so “ship nightly” cannot succeed as written.
- Discord configuration is split across different env sources:
  - Claude reads `~/.config/compound-learning/config.env`.
  - OpenCode systemd services read `~/.config/opencode-compound/environment.conf`.
  - These can point to different Discord channels/webhooks, making “no notifications” ambiguous.
- OpenCode has multiple timers at overlapping times; at least one set appears legacy/outdated.

## Status Snapshot (As Of 2026-02-03)
- Claude review: last log activity 2026-02-01 (manual/out-of-schedule).
- Claude auto-compound: last log activity 2026-02-01; shows git repo errors.
- OpenCode systemd timers: last attempted runs 2026-02-02 at scheduled times; failing early.
- “Learnings”: present in at least `ai-eng-system/CLAUDE.md` for 2026-02-01.
- “Commits/push”: evidence is weak right now; only `rune` shows a recent `chore: compound learning from session` commit (suggesting other “✅ Learning extracted” log lines may be false positives due to missing `pipefail` / masked git failures).

## Primary Root Causes For “No Discord Notifications”
1) The scheduled jobs are not actually running to completion (cron path/redirection breakage; systemd services failing early).
2) Discord sending is intentionally silent on failure (webhook HTTP errors are not logged).
3) Claude/OpenCode may be configured to post to different Discord webhooks (split env sources).

## Security Note (Action Required)
- There are credential-like values present in local config files used by systemd. Treat those as sensitive and avoid printing them in logs.
- Recommended hygiene after we stabilize: rotate any long-lived tokens/webhooks that have been exposed broadly.

## Plan Of Action

### Phase 0: Stop The Bleeding (No More Phantom Runs)
- Choose one scheduler per pipeline and disable duplicates.
  - Recommended: keep systemd timers for OpenCode; either migrate Claude to systemd or fix cron.
- Success criteria:
  - Only one set of timers/jobs active for each pipeline.
  - A single log location per pipeline that updates every run.

Concrete actions (execution phase):
- OpenCode: keep only one of:
  - `opencode-multi-project-review.timer` + `opencode-multi-project-auto-compound.timer` (recommended)
  - OR `opencode-compound-review.timer` + `opencode-auto-compound.timer` (if those are the intended ones)
- Disable the other pair to avoid double runs and double Discord noise.

### 1) Scheduling & “Is It Running?” Verification
- Audit Claude cron entries and the installer that generated them.
- Decide on the long-term scheduler:
  - Recommended: move Claude to systemd user timers to match OpenCode.
  - Alternative: keep cron but fix paths and ensure logs directories exist.
- For OpenCode: determine which timer set is canonical (recommend multi-project) and disable duplicates to reduce noise and wasted runs.

Verification checklist (commands to run during execution phase):
- `crontab -l | grep -E "claude|compound"`
- `systemctl --user list-timers | grep -E "opencode|compound"`
- `ls -la /home/vitruvius/git/logs`
- `tail -n 200 /home/vitruvius/git/logs/claude-compound-review.log`
- `tail -n 200 /home/vitruvius/git/logs/claude-auto-compound.log`
- `journalctl --user -u opencode-multi-project-review.service -n 200 --no-pager`
- `journalctl --user -u opencode-multi-project-auto-compound.service -n 200 --no-pager`

### 2) Execution Correctness Fixes (Minimal, High-Leverage)
- Add strict bash mode (`set -eEuo pipefail`) where appropriate and adjust pipelines so failures are not masked by `tee`.
- Fix working directory assumptions:
  - `scripts/setup-claude-scheduling.sh`: compute repo root correctly and redirect logs to the intended location.
  - `scripts/claude-auto-compound.sh`: run git operations in an actual repository (likely the compound-learning-system repo, or explicitly target a project repo).
  - `scripts/loop.sh`: ensure log directory exists and reference the PRD path deterministically.
- Resolve interface mismatch:
  - `scripts/analyze-report.sh` outputs two lines today; `scripts/opencode-auto-compound.sh` expects JSON + `jq`. Unify the contract.

Success criteria:
- A failed `claude/opencode` invocation reliably fails the run and is visible in logs.
- Auto-compound can create a branch in a real repo without `fatal: not a git repository`.
- `loop-execution.log` is created reliably and contains deterministic references (no dependence on current cwd).

Implementation notes (what to change later):
- Prefer `set -eEuo pipefail` + explicit `mkdir -p` for log dirs.
- Avoid `cmd | tee ...` for control flow; if you need tee, capture exit via `PIPESTATUS[0]`.
- Add overlap protection: `flock` around each scheduled entrypoint to prevent two runs colliding.
- Add a “dirty repo” gate per project: if `git status --porcelain` not empty, skip + notify.

### 3) Discord Notifications: Make Them Observable
- Ensure both systems intentionally use the same Discord webhook (or explicitly document that they are different).
- Stop “silent failure” for Discord sending:
  - Log HTTP status code and response body on failure (without logging the webhook token).
- Add scheduler-level alerts:
  - systemd `OnFailure=` handlers for each service to notify Discord when a run fails.
- Add a heartbeat/freshness check:
  - Alert if no successful run marker or no log updates within N hours.

Success criteria:
- You receive at least one Discord message for: start, success, and failure.
- A “heartbeat” message arrives daily even if no work is done.

Recommended standard notification payloads:
- START: includes pipeline name + hostname + run id
- SUCCESS: includes counts (projects reviewed, failures) + links/paths to logs
- FAILURE: includes service name + exit code + last 20 log lines (redacted)

### 4) End-to-End Validation
- Run one manual Claude review on a single project and verify:
  - CLAUDE.md updated
  - commit created and (optionally) pushed
  - Discord message received
  - logs show true success/failure (not masked)
- Run one manual OpenCode review similarly.
- Confirm the next scheduled runs will execute successfully (cron/systemd status + log updates + Discord notifications).

Guardrails during validation:
- Run with a single project first (no multi-project blast radius).
- Prefer a “no-push” mode until signals are trustworthy.
- Add lock/overlap protection (e.g., `flock`) before re-enabling nightly schedules.

Acceptance: two consecutive nights with:
- logs updated at scheduled times
- Discord messages received
- no unexpected dirty working trees left behind

### 5) Documentation Alignment
- Update docs to match the actual configuration model (central config vs `.env.local`).
- Add a short runbook: “check schedule”, “check last run”, “check Discord”, “what to do on failure”.

Deliverables:
- `docs/RUNBOOK.md` (or equivalent) with 5-minute diagnosis steps.
- One “source of truth” config path documented and used by both systems.

## Decisions Needed

Pick defaults unless you prefer otherwise:
- Discord: unify to one webhook/channel for both systems (DECIDED: yes).
- Scheduler: move Claude onto systemd user timers and remove cron (recommended) OR fix cron and keep systemd only for OpenCode.
- Safety: default to “no push / no PR creation” until the first 2 nights are clean, then re-enable.

## Remaining Question (Low Risk, But Clarifies The Fix)
## Remaining Decision (Implementation Detail)
See `IMPLEMENT_DECISION.md` for the unified webhook approach:
- We will use the existing Discord webhook from Claude's config as a single source of truth for both systems.
- Update OpenCode systemd services to use the same `EnvironmentFile=` path as Claude.
- Remove the separate `~/.config/opencode-compound/environment.conf` file to avoid confusion.
