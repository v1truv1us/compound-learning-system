#!/bin/bash
# Quick copy script - transfers all files to ~/git on your Mac

set -e

echo "=== Compound Learning System - Quick Copy to ~/git ==="
echo ""

# Check if we're in the compound-learning-system directory
if [ ! -f README.md ]; then
  echo "❌ Error: Run this script from the compound-learning-system directory"
  echo ""
  echo "Usage:"
  echo "  cd ~/Downloads/compound-learning-system"
  echo "  bash QUICK_COPY.sh"
  exit 1
fi

# Verify target directory exists
if [ ! -d ~/git ]; then
  echo "❌ Error: ~/git directory not found"
  echo ""
  echo "Please create it first:"
  echo "  mkdir -p ~/git/{scripts,bin,logs}"
  exit 1
fi

echo "✅ Found compound-learning-system package"
echo "✅ Found ~/git directory"
echo ""

# Copy documentation
echo "Copying documentation..."
cp -v docs/*.md ~/git/ || echo "⚠️  Note: Some docs may already exist"

# Create directories if needed
mkdir -p ~/git/scripts
mkdir -p ~/git/bin
mkdir -p ~/git/logs

# Copy scripts
echo "Copying scripts..."
cp -v scripts/claude-*.sh ~/git/scripts/
cp -v scripts/setup-claude-scheduling.sh ~/git/

# Make scripts executable
echo "Making scripts executable..."
chmod +x ~/git/scripts/claude-*.sh
chmod +x ~/git/setup-claude-scheduling.sh

# Copy environment template
echo "Copying environment configuration..."
cp -v config/.env.local.template ~/git/scripts/.env.local.template
cp -v config/.env.local.template ~/git/bin/.env.local.template

# Create symlinks in bin
echo "Creating symlinks in ~/git/bin/..."
cd ~/git/bin
ln -sf ../scripts/claude-compound-review.sh claude-compound-review
ln -sf ../scripts/claude-auto-compound.sh claude-auto-compound

echo ""
echo "✅ Files copied successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/git/scripts/.env.local and add your Discord webhook URL"
echo "  2. Edit ~/git/bin/.env.local and add your Discord webhook URL"
echo "  3. Run: cd ~/git && ./setup-claude-scheduling.sh"
echo "  4. Test: ./scripts/claude-compound-review.sh"
echo ""
echo "For detailed instructions, see:"
echo "  ~/git/INSTALL_ON_MAC.md"
echo "  ~/git/README.md"
echo ""
