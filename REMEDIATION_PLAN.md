# Remediation Plan: Compound Learning System

**Status**: In Progress | **Last Updated**: 2026-02-03 | **Plan Phase**: Ready for Implementation

## Executive Summary

The compound learning system has been partially fixed. We've unified Discord webhook configuration, added strict bash modes to Claude scripts, disabled duplicate timers, and documented the system. However, **6 critical issues remain** that prevent reliable nightly automation and Discord notifications.

This plan consolidates all remaining work into actionable phases with clear success criteria.

---

## Current State (As of 2026-02-03)

### ✅ Completed
- [x] Discord webhook unified to `~/.config/compound-learning/config.env`
- [x] OpenCode systemd services updated to use shared config
- [x] Duplicate OpenCode timers disabled (`opencode-compound-review.timer`, `opencode-auto-compound.timer`)
- [x] Strict bash mode added to `claude-compound-review.sh`, `claude-auto-compound.sh`, `loop.sh`
- [x] `claude-auto-compound.sh` fixed to use `$COMPOUND_ROOT` for git operations
- [x] `loop.sh` now ensures logs directory exists
- [x] Documentation created: `PLAN.md`, `IMPLEMENT_DECISION.md`, `docs/RUNBOOK.md`
- [x] Cron fix script created: `scripts/fix-claude-cron-paths.sh`

### ❌ Remaining Issues

| Priority | Issue | Impact | Files Affected |
|----------|-------|--------|----------------|
| **P0** | Broken cron paths | Claude jobs never execute | `crontab` entries malformed |
| **P0** | JSON/text mismatch | OpenCode auto-compound fails | `analyze-report.sh` vs `opencode-auto-compound.sh` |
| **P1** | No overlap protection | Duplicate runs possible | All scheduled entrypoints |
| **P1** | Missing strict mode | False positives in logs | `opencode-*.sh` scripts |
| **P2** | Silent Discord failures | No visibility when notifications fail | `common.sh:send_discord()` |
| **P2** | Outdated docs | References to old `.env.local` paths | `README.md`, `docs/CLAUDE.md` |

---

## Phase 1: Critical Path Fixes (P0)

### 1.1 Fix Broken Cron Paths

**Problem**: Current crontab has malformed paths:
```
# WRONG - cd into scripts then run ./scripts/
cd /home/vitruvius/git/compound-learning-system/scripts && ./scripts/claude-compound-review.sh
```

**Solution**: Run the fix script and regenerate cron entries:

```bash
# 1. Remove old broken entries
crontab -e  # Delete the two claude compound lines manually

# 2. Run the fix script
./scripts/fix-claude-cron-paths.sh

# 3. Re-install with correct paths
./scripts/setup-claude-scheduling.sh
```

**Expected Result**:
```
0 23 * * * cd "/home/vitruvius/git/compound-learning-system" && ./scripts/claude-compound-review.sh >> "/home/vitruvius/git/compound-learning-system/logs/claude-compound-review.log" 2>&1
30 23 * * * cd "/home/vitruvius/git/compound-learning-system" && ./scripts/claude-auto-compound.sh >> "/home/vitruvius/git/compound-learning-system/logs/claude-auto-compound.log" 2>&1
```

**Success Criteria**:
- [ ] Cron entries reference `$GIT_ROOT` (compound-learning-system root), not `scripts/` subdirectory
- [ ] Log paths point to `logs/` directory at repo root
- [ ] Manual test: `cd /home/vitruvius/git/compound-learning-system && ./scripts/claude-compound-review.sh --help` works

---

### 1.2 Resolve JSON/Text Interface Mismatch

**Problem**: `analyze-report.sh` outputs plain text (2 lines), but `opencode-auto-compound.sh` expects JSON:

```bash
# analyze-report.sh outputs:
"Fix authentication middleware"
"compound-fix-authentication-middleware-1738642800"

# opencode-auto-compound.sh expects:
ANALYSIS=$("$SCRIPT_DIR/analyze-report.sh" "$LATEST_REPORT")
PRIORITY_ITEM=$(echo "$ANALYSIS" | jq -r '.priority_item')  # FAILS - not JSON!
```

**Decision Needed**: Choose one approach:

**Option A: Fix analyze-report.sh to output JSON** (Recommended)
```bash
# Change analyze-report.sh output:
echo '{"priority_item":"'$PRIORITY_ITEM'","branch_name":"'$BRANCH_NAME'"}'
```

**Option B: Fix opencode-auto-compound.sh to parse plain text**
```bash
# Change opencode-auto-compound.sh:
ANALYSIS=$("$SCRIPT_DIR/analyze-report.sh" "$LATEST_REPORT")
PRIORITY_ITEM=$(echo "$ANALYSIS" | head -1)
BRANCH_NAME=$(echo "$ANALYSIS" | tail -1)
```

**Recommendation**: Option A is cleaner and allows future extensibility. Update `analyze-report.sh` to output JSON.

**Success Criteria**:
- [ ] `analyze-report.sh test-report.md` outputs valid JSON
- [ ] `opencode-auto-compound.sh` successfully parses the JSON
- [ ] Manual test passes without jq errors

---

## Phase 2: Reliability Improvements (P1)

### 2.1 Add Overlap Protection

**Problem**: If a job runs longer than the interval between scheduled runs, multiple instances can overlap causing conflicts.

**Solution**: Add `flock` to all scheduled entrypoints:

**For Cron**:
```bash
# In setup-claude-scheduling.sh, wrap commands with flock:
add_cron_job \
  "0 23 * * *" \
  "flock -n /tmp/claude-compound.lock -c 'cd \"\$GIT_ROOT\" && ./scripts/claude-compound-review.sh >> \"\$GIT_ROOT/logs/claude-compound-review.log\" 2>&1'" \
  "Claude Compound Review"
```

**For Systemd** (alternative to cron):
```ini
# Add to [Service] section in opencode-*.service:
ExecStartPre=/usr/bin/flock -n /tmp/opencode-multi-review.lock -c "echo 'Lock acquired'"
ExecStopPost=/bin/rm -f /tmp/opencode-multi-review.lock
```

**Success Criteria**:
- [ ] Second concurrent run is blocked with clear log message
- [ ] Lock files cleaned up after job completes

---

### 2.2 Add Strict Bash Mode to OpenCode Scripts

**Problem**: `opencode-compound-review.sh` and `opencode-auto-compound.sh` lack `set -eEuo pipefail`, allowing failures to go undetected.

**Solution**:
```bash
# Add to top of both scripts:
set -eEuo pipefail
```

**Note**: After adding strict mode, test thoroughly as some constructs may need adjustment (e.g., `timeout` with `|| true`).

**Success Criteria**:
- [ ] Scripts fail fast on errors
- [ ] No false "success" logs when commands fail
- [ ] Manual tests pass with strict mode enabled

---

## Phase 3: Observability & Documentation (P2)

### 3.1 Improve Discord Error Logging

**Problem**: `send_discord()` in `common.sh` silently ignores curl failures:

```bash
# Current (silent failure):
curl -s -X POST "$DISCORD_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$payload" >/dev/null 2>&1 || true
```

**Solution**: Log HTTP status without exposing tokens:

```bash
send_discord() {
  local title="$1"
  local description="$2"
  local color="${3:-3447003}"

  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    log "Discord webhook not configured, skipping notification"
    return 0
  fi

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

  # Log status code without exposing URL/token
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$DISCORD_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$payload" 2>/dev/null)

  if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
    log "Discord notification sent successfully (HTTP $http_code)"
  else
    log_error "Discord notification failed (HTTP $http_code)"
    return 1
  fi
}
```

**Success Criteria**:
- [ ] Successful notifications log "HTTP 200/204"
- [ ] Failed notifications log "HTTP XXX" error
- [ ] Webhook URL is never logged

---

### 3.2 Update Documentation

**Files to Update**:

1. **README.md**: Change references from `.env.local` to `~/.config/compound-learning/config.env`

2. **docs/CLAUDE.md**: Update configuration section to reflect:
   - Single config file location
   - No more split config
   - Centralized Discord webhook

3. **docs/RUNBOOK.md**: Add new troubleshooting section for:
   - "Job blocked by lock file"
   - "JSON parse error in auto-compound"

**Success Criteria**:
- [ ] All docs reference `~/.config/compound-learning/config.env`
- [ ] No mentions of legacy `.env.local` paths
- [ ] Runbook includes lock file troubleshooting

---

## Phase 4: Validation

### 4.1 End-to-End Manual Test

Test each component after fixes:

```bash
# Test 1: Claude review on single project
cd /home/vitruvius/git/compound-learning-system
./scripts/claude-compound-review.sh --project fleettools
# Verify: CLAUDE.md updated, Discord notification sent

# Test 2: OpenCode review on single project
./scripts/opencode-compound-review.sh --project fleettools
# Verify: No jq errors, Discord notification sent

# Test 3: Verify cron paths
./scripts/setup-claude-scheduling.sh --dry-run
# Verify: Paths are correct

# Test 4: Test overlap protection
# Run two instances simultaneously, verify second is blocked
```

### 4.2 Two-Night Burn-In

After all fixes:

**Night 1**:
- [ ] Cron jobs execute at scheduled times (22:30, 23:00, 23:15, 23:30)
- [ ] Logs updated with timestamps
- [ ] Discord receives START and SUCCESS/FAILURE messages
- [ ] No "fatal: not a git repository" errors

**Night 2**:
- [ ] Same as Night 1
- [ ] Confirm consistency across both nights
- [ ] Verify no duplicate runs (check for overlapping timestamps)

---

## Implementation Checklist

### Phase 1: Critical
- [ ] Run `fix-claude-cron-paths.sh` and re-install cron jobs
- [ ] Update `analyze-report.sh` to output JSON (or fix `opencode-auto-compound.sh` to parse text)
- [ ] Test both scripts manually

### Phase 2: Reliability
- [ ] Add `flock` to cron entries in `setup-claude-scheduling.sh`
- [ ] Add `flock` to systemd services (optional, can be done in systemd config)
- [ ] Add `set -eEuo pipefail` to `opencode-compound-review.sh`
- [ ] Add `set -eEuo pipefail` to `opencode-auto-compound.sh`
- [ ] Test with strict mode

### Phase 3: Observability
- [ ] Update `send_discord()` in `common.sh` to log HTTP status
- [ ] Update `README.md` with correct config path
- [ ] Update `docs/CLAUDE.md` with unified config info
- [ ] Add lock file troubleshooting to `docs/RUNBOOK.md`

### Phase 4: Validation
- [ ] Manual test each component
- [ ] Monitor for 2 consecutive nights
- [ ] Verify Discord notifications arrive consistently

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Strict mode breaks working scripts | Medium | High | Test thoroughly before enabling, use `|| true` where intentional |
| Cron still broken after fix | Low | High | Verify paths manually before relying on automation |
| JSON change affects other callers | Low | Medium | Check if `analyze-report.sh` used elsewhere; grep codebase |
| Lock files not cleaned up | Low | Medium | Add cleanup on script exit trap |
| Discord webhook rate limited | Low | Low | Add exponential backoff if needed |

---

## Open Questions

1. **Should we migrate Claude from cron to systemd timers for consistency?**
   - Pros: Single scheduler type, better logging via journald
   - Cons: More migration work, cron is simpler
   - Recommendation: Fix cron first, consider migration as future enhancement

2. **Should we add systemd OnFailure= handlers for Discord alerts when services fail?**
   - Pros: Immediate notification of failures
   - Cons: More complexity
   - Recommendation: Add after Phase 1-3 are stable

3. **What's the expected behavior when `COMPOUND_ROOT` is not set?**
   - Current: Scripts may fail or use wrong directory
   - Should we add validation in `common.sh`?
   - Recommendation: Add validation check in `load_config()`

---

## Appendix: Quick Commands

```bash
# Check current cron entries
crontab -l | grep -E "claude|compound"

# Check systemd timers
systemctl --user list-timers | grep -E "opencode|compound"

# View recent logs
tail -n 50 /home/vitruvius/git/compound-learning-system/logs/claude-compound-review.log
journalctl --user -u opencode-multi-project-review.service -n 50 --no-pager

# Test Discord webhook manually
curl -X POST "$DISCORD_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"embeds":[{"title":"Test","description":"Works!","color":3066993}]}'

# Check config
ls -la ~/.config/compound-learning/
cat ~/.config/compound-learning/config.env | grep -v TOKEN
```

---

**Document Version**: 1.0  
**Next Review**: After Phase 1 completion  
**Owner**: Compound Learning System Maintenance
