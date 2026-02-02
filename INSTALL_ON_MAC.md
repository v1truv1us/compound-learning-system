# Compound Learning System - Installation on Mac

This folder contains everything needed to set up the compound learning system on your Mac.

## Quick Install

### Step 1: Prepare the folder
```bash
# Copy this folder to your Mac (via airdrop, USB, or cloud)
# Then navigate to it
cd ~/Downloads/compound-learning-system
# or wherever you copied it

# Or use scp to copy from Linux:
scp -r user@linux-machine:~/git/compound-learning-system ~/Downloads/
```

### Step 2: Move files to your ~/git directory
```bash
# From the compound-learning-system folder:
cp -v docs/*.md ~/git/
cp -v scripts/claude-*.sh ~/git/scripts/
cp -v scripts/setup-claude-scheduling.sh ~/git/

# Make scripts executable
chmod +x ~/git/scripts/claude-*.sh
chmod +x ~/git/setup-claude-scheduling.sh
```

### Step 3: Set up environment
```bash
# Copy environment template
cp config/.env.local.template ~/git/scripts/.env.local
cp config/.env.local.template ~/git/bin/.env.local

# Edit and add your Discord webhook URL
nano ~/git/scripts/.env.local
# Paste: DISCORD_WEBHOOK_URL="your_webhook_url_here"

nano ~/git/bin/.env.local
# Paste: DISCORD_WEBHOOK_URL="your_webhook_url_here"
```

### Step 4: Create symlinks in bin/
```bash
cd ~/git/bin

# Create symlinks for Claude scripts
ln -s ../scripts/claude-compound-review.sh claude-compound-review
ln -s ../scripts/claude-auto-compound.sh claude-auto-compound

# Verify they work
ls -la claude*
```

### Step 5: Install Claude CLI (if not already installed)
```bash
npm install -g claude

# Verify installation
which claude
claude --version
```

### Step 6: Set up scheduling
```bash
cd ~/git

# Setup Claude cron jobs
bash ./setup-claude-scheduling.sh

# If you also want OpenCode compound:
# Copy and run opencode-compound/setup-multi-project-timers.sh
bash ./opencode-compound/setup-multi-project-timers.sh
```

### Step 7: Test the system
```bash
# Test Claude review
./scripts/claude-compound-review.sh

# Monitor logs
tail -f logs/claude-compound-review.log

# Check Discord for notifications
```

### Step 8: Verify scheduling is active
```bash
# Check cron jobs
crontab -l | grep compound

# Check systemd timers (if using OpenCode)
systemctl --user list-timers | grep opencode
```

## What's in This Folder

```
compound-learning-system/
├── docs/
│   ├── CLAUDE.md                      # Main documentation
│   ├── SCHEDULING_SETUP.md            # Cron setup guide
│   ├── COMPOUND_SETUP_COMPLETE.md     # What was created
│   └── SCHEDULING_ACTIVE.md           # Status and monitoring
├── scripts/
│   ├── claude-compound-review.sh      # Reviews all projects
│   ├── claude-auto-compound.sh        # Implements priority work
│   └── setup-claude-scheduling.sh     # Cron automation setup
├── config/
│   ├── .env.local.example             # Example environment
│   └── .env.local.template            # Template to fill in
├── INSTALL_ON_MAC.md                  # This file
└── README.md                          # Quick reference
```

## File Placement on Mac

After installation, your ~/git structure should look like:

```
~/git/
├── scripts/
│   ├── claude-compound-review.sh      ← Copied from this folder
│   ├── claude-auto-compound.sh        ← Copied from this folder
│   └── setup-claude-scheduling.sh     ← Copied from this folder
│   └── .env.local                     ← Created from template
├── bin/
│   ├── claude-compound-review         ← Symlink to scripts/
│   ├── claude-auto-compound           ← Symlink to scripts/
│   └── .env.local                     ← Created from template
├── CLAUDE.md                          ← Copied from docs/
├── SCHEDULING_SETUP.md                ← Copied from docs/
├── COMPOUND_SETUP_COMPLETE.md         ← Copied from docs/
└── SCHEDULING_ACTIVE.md               ← Copied from docs/
```

## macOS-Specific Notes

### Using launchd instead of cron (Optional)

While cron works fine on Mac, you can use launchd for more control:

1. The setup script uses cron by default
2. To use launchd instead, create these plist files in `~/Library/LaunchAgents/`:

```bash
# Create the directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Copy the plist templates from the opencode-compound setup
# Or manually create them following macOS launchd format
```

### Keep Mac Awake During Automation

If your Mac sleeps at 11:00 PM, use caffeinate to keep it awake:

```bash
# In your crontab, add before the compound jobs:
# Keep awake from 10 PM to 12:30 AM
30 22 * * * /usr/bin/caffeinate -i -t 5400 &
```

Or add a launchd plist to handle this automatically.

### Verify Installation

```bash
# Check Claude is installed
which claude
claude --version

# Check cron jobs
crontab -l

# Check logs will be created
ls -la ~/git/logs/

# Test manual run
~/git/scripts/claude-compound-review.sh --project fleettools
```

## Troubleshooting on Mac

### "Command not found: claude"
```bash
# Install Claude CLI
npm install -g claude

# Verify it's in your PATH
which claude
echo $PATH
```

### "Permission denied" when running scripts
```bash
# Make scripts executable
chmod +x ~/git/scripts/claude-*.sh
chmod +x ~/git/setup-claude-scheduling.sh
```

### Cron jobs not running
```bash
# Check cron is working
crontab -l

# View cron logs on Mac
log stream --predicate 'process == "cron"' --level debug
```

### Discord notifications not arriving
```bash
# Check environment is loaded
source ~/git/scripts/.env.local
echo $DISCORD_WEBHOOK_URL

# Test webhook manually
curl -X POST "$DISCORD_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"embeds":[{"title":"Test","description":"Works!","color":3066993}]}'
```

## Documentation

Read these files in order:

1. **COMPOUND_SETUP_COMPLETE.md** - Overview of what was created
2. **CLAUDE.md** - Complete system documentation
3. **SCHEDULING_SETUP.md** - How to configure cron
4. **SCHEDULING_ACTIVE.md** - Current status and monitoring

## Next Steps

1. Copy files to ~/git/
2. Add Discord webhook to .env.local
3. Run manual test
4. Set up scheduling
5. Monitor Discord and logs

Your compound learning system will now run every night on your Mac!

---

**For detailed system documentation, see docs/CLAUDE.md**
