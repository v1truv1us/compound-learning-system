import { Box, Text, useInput, useApp } from '@opentui/core';
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

const colorCyan = '\x1b[36m';
const colorGreen = '\x1b[32m';
const colorYellow = '\x1b[33m';
const colorRed = '\x1b[31m';
const colorWhite = '\x1b[37m';
const colorGray = '\x1b[90m';
const colorReset = '\x1b[0m';

interface SetupState {
  currentStep: number;
  webhookUrl: string;
  claudeModel: string;
  opencodeModel: string;
  platform: string;
  completed: boolean;
}

const state: SetupState = {
  currentStep: 0,
  webhookUrl: '',
  claudeModel: 'claude-opus-4-5',
  opencodeModel: 'opencode-default',
  platform: process.platform === 'darwin' ? 'macos' : 'linux',
  completed: false,
};

function printHeader() {
  console.clear();
  console.log(
    `${colorCyan}╔════════════════════════════════════════════════════════════╗${colorReset}`
  );
  console.log(
    `${colorCyan}║${colorReset}  🚀 ${colorWhite}Compound Learning System Setup${colorReset}${colorCyan}                  ║${colorReset}`
  );
  console.log(
    `${colorCyan}╚════════════════════════════════════════════════════════════╝${colorReset}\n`
  );
}

function printSection(title: string) {
  console.log(
    `\n${colorYellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colorReset}`
  );
  console.log(`${colorYellow}  ${title}${colorReset}`);
  console.log(
    `${colorYellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colorReset}\n`
  );
}

function printSuccess(message: string) {
  console.log(`${colorGreen}✓${colorReset} ${colorWhite}${message}${colorReset}`);
}

function printError(message: string) {
  console.log(`${colorRed}✗${colorReset} ${colorWhite}${message}${colorReset}`);
}

function printInfo(message: string) {
  console.log(`${colorGray}ℹ${colorReset} ${colorGray}${message}${colorReset}`);
}

async function promptInput(
  prompt: string,
  defaultValue: string = ''
): Promise<string> {
  process.stdout.write(
    `${colorCyan}?${colorReset} ${colorWhite}${prompt}${colorReset}`
  );
  if (defaultValue) {
    process.stdout.write(` ${colorGray}[${defaultValue}]${colorReset}`);
  }
  process.stdout.write(`: `);

  return new Promise((resolve) => {
    let input = '';
    process.stdin.setRawMode(true);
    process.stdin.resume();

    process.stdin.on('data', (char) => {
      if (char.toString() === '\n') {
        process.stdin.setRawMode(false);
        process.stdin.pause();
        resolve(input || defaultValue);
      } else if (char.toString() === '\u0003') {
        process.exit();
      } else {
        input += char;
        process.stdout.write(char);
      }
    });
  });
}

async function runSetup() {
  printHeader();
  printSection('Welcome');

  console.log(`${colorWhite}This setup will configure your compound learning system for:${colorReset}\n`);
  console.log(`  ${colorCyan}•${colorReset} Learning extraction from your projects`);
  console.log(`  ${colorCyan}•${colorReset} Automatic implementation of improvements`);
  console.log(`  ${colorCyan}•${colorReset} Nightly scheduling (11:00 PM & 11:30 PM)`);
  console.log(`  ${colorCyan}•${colorReset} Discord notifications\n`);

  const startSetup = await promptInput('Continue with setup? (y/n)', 'y');
  if (startSetup.toLowerCase() !== 'y') {
    printInfo('Setup cancelled');
    process.exit(0);
  }

  // Configuration step
  printHeader();
  printSection('Configuration');

  const configDir = path.join(process.env.HOME || '~', '.config', 'compound-learning');
  const configFile = path.join(configDir, 'config.env');

  if (fs.existsSync(configFile)) {
    printSuccess(`Config file exists at ${configFile}`);
    const updateConfig = await promptInput('Update configuration? (y/n)', 'n');
    if (updateConfig.toLowerCase() !== 'y') {
      console.log('');
      await setupScheduling();
      printFinalSummary();
      return;
    }
  }

  console.log(`\n${colorWhite}Discord Webhook (optional)${colorReset}\n`);
  printInfo(
    'Get your webhook URL from: Discord → Server → Channel Settings → Integrations → Webhooks'
  );
  console.log('');

  state.webhookUrl = await promptInput('Discord webhook URL', '');

  console.log(`\n${colorWhite}Claude Model${colorReset}\n`);
  state.claudeModel = await promptInput(
    'Claude model',
    'claude-opus-4-5'
  );

  console.log(`\n${colorWhite}OpenCode Model${colorReset}\n`);
  state.opencodeModel = await promptInput(
    'OpenCode model',
    'opencode-default'
  );

  // Write config
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }

  const configContent = `# Compound Learning System Configuration
# Central config sourced by all scripts

# Discord Notifications
DISCORD_WEBHOOK_URL="${state.webhookUrl}"

# Claude model configuration
CLAUDE_MODEL="${state.claudeModel}"
OPENCODE_MODEL="${state.opencodeModel}"

# Execution timeouts (seconds)
CLAUDE_TIMEOUT=600
OPENCODE_TIMEOUT=600

# Projects root directory
GIT_ROOT="$HOME/git"
`;

  fs.writeFileSync(configFile, configContent);
  printSuccess(`Config saved to ${configFile}`);

  // Setup scheduling
  await setupScheduling();

  // Final summary
  printFinalSummary();
}

async function setupScheduling() {
  printHeader();
  printSection('Platform Detection & Scheduling');

  const scriptDir = process.cwd();
  
  // Make scripts executable
  try {
    execSync(`chmod +x ${scriptDir}/scripts/*.sh`);
    printSuccess('Scripts made executable');
  } catch (e) {
    printError('Failed to make scripts executable');
  }

  console.log('');

  if (state.platform === 'macos') {
    printSuccess('macOS detected');
    console.log('');
    setupMacOS(scriptDir);
  } else if (state.platform === 'linux') {
    printSuccess('Linux detected');
    console.log('');
    setupLinux(scriptDir);
  } else {
    printError(`Unknown OS: ${state.platform}`);
    process.exit(1);
  }
}

function setupLinux(scriptDir: string) {
  console.log(`${colorCyan}▶${colorReset} ${colorWhite}Installing cron jobs...${colorReset}\n`);

  try {
    execSync(`${scriptDir}/scripts/setup-claude-scheduling.sh > /dev/null 2>&1`);
    printSuccess('Cron jobs installed');
  } catch (e) {
    printError('Failed to install cron jobs');
  }

  console.log('');
  console.log(`${colorCyan}Schedule:${colorReset}`);
  console.log(`  ${colorGray}0 23 * * *${colorReset}  → Claude Compound Review (11:00 PM)`);
  console.log(`  ${colorGray}30 23 * * *${colorReset} → Claude Auto-Compound (11:30 PM)`);
  console.log('');
  console.log(`${colorCyan}View jobs:${colorReset} ${colorGray}crontab -l${colorReset}`);
  console.log(`${colorCyan}Edit jobs:${colorReset} ${colorGray}crontab -e${colorReset}`);
}

function setupMacOS(scriptDir: string) {
  console.log(`${colorCyan}▶${colorReset} ${colorWhite}Installing launchd plists...${colorReset}\n`);

  const home = process.env.HOME || '~';
  const launchdDir = `${home}/Library/LaunchAgents`;

  try {
    fs.mkdirSync(launchdDir, { recursive: true });

    const reviewPlist = `${scriptDir}/config/launchd/com.compound.review.plist`;
    const autoPlist = `${scriptDir}/config/launchd/com.compound.auto.plist`;

    if (fs.existsSync(reviewPlist)) {
      execSync(
        `cp ${reviewPlist} ${launchdDir}/com.compound.review.plist`
      );
    }
    if (fs.existsSync(autoPlist)) {
      execSync(
        `cp ${autoPlist} ${launchdDir}/com.compound.auto.plist`
      );
    }

    // Update paths in plists
    execSync(
      `sed -i '' "s|/Users/vitruvius|${home}|g" ${launchdDir}/com.compound.*.plist`
    );
    execSync(
      `sed -i '' "s|/Users/vitruvius/git/compound-learning-system|${scriptDir}|g" ${launchdDir}/com.compound.*.plist`
    );

    // Load agents
    execSync(
      `launchctl load ${launchdDir}/com.compound.review.plist 2>/dev/null || true`
    );
    execSync(
      `launchctl load ${launchdDir}/com.compound.auto.plist 2>/dev/null || true`
    );

    printSuccess('Launchd jobs installed');
  } catch (e) {
    printError('Failed to install launchd jobs');
  }

  console.log('');
  console.log(`${colorCyan}Services:${colorReset}`);
  console.log(`  ${colorGray}com.compound.review${colorReset}  → Claude Compound Review (11:00 PM)`);
  console.log(`  ${colorGray}com.compound.auto${colorReset}    → Claude Auto-Compound (11:30 PM)`);
  console.log('');
  console.log(
    `${colorCyan}View status:${colorReset} ${colorGray}launchctl list | grep compound${colorReset}`
  );
  console.log(
    `${colorCyan}Unload:${colorReset} ${colorGray}launchctl unload ~/Library/LaunchAgents/com.compound.*.plist${colorReset}`
  );
}

function printFinalSummary() {
  printHeader();
  printSection('Setup Complete ✓');

  console.log(`${colorGreen}═══════════════════════════════════════════════════════════${colorReset}`);
  console.log('');
  console.log(`${colorCyan}Configuration:${colorReset}`);
  const home = process.env.HOME || '~';
  console.log(
    `  ${colorGray}Location:${colorReset} ${home}/.config/compound-learning/config.env`
  );
  console.log('');
  console.log(`${colorCyan}System Paths:${colorReset}`);
  console.log(
    `  ${colorGray}Scripts:${colorReset}    ${process.cwd()}/scripts/`
  );
  console.log(`  ${colorGray}Logs:${colorReset}       ${home}/git/logs/`);
  console.log(
    `  ${colorGray}Reports:${colorReset}    ${process.cwd()}/reports/`
  );
  console.log('');
  console.log(`${colorCyan}What Happens Next:${colorReset}`);
  console.log(
    `  ${colorGray}11:00 PM${colorReset} - Extract learnings from all projects`
  );
  console.log(
    `  ${colorGray}11:30 PM${colorReset} - Implement improvements automatically`
  );
  console.log(`  ${colorGray}Nightly${colorReset}  - Discord notifications sent`);
  console.log('');
  console.log(`${colorCyan}Monitor Your System:${colorReset}`);
  console.log(
    `  ${colorGray}tail -f ${home}/git/logs/claude-compound-review.log${colorReset}`
  );
  console.log(
    `  ${colorGray}tail -f ${home}/git/logs/claude-auto-compound.log${colorReset}`
  );
  console.log('');
  console.log(
    `${colorGreen}═══════════════════════════════════════════════════════════${colorReset}`
  );
  console.log('');
  console.log(
    `  🚀 ${colorWhite}Your codebase will learn and ship every night!${colorReset}\n`
  );
}

runSetup().catch(console.error);
