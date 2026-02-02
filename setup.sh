#!/bin/bash
# setup.sh - Wrapper for OpenTUI-based setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Compound Learning System Setup"
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is required but not installed"
    echo "Please install Node.js from: https://nodejs.org/"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
    echo "📦 Installing dependencies..."
    cd "$SCRIPT_DIR"
    npm install --quiet
    echo "✅ Dependencies installed"
    echo ""
fi

# Run the TypeScript setup
cd "$SCRIPT_DIR"
npx tsx setup.ts
