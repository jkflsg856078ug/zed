#!/usr/bin/env bash
#
# Zed Fork - Quick Start Script
# This script gets you building Zed in under 1 minute!
#

set -e

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Zed Editor - Local Build Quick Start                       ║
║   With Remote MCP Server Support                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

echo "This script will:"
echo "  1. Check prerequisites"
echo "  2. Install dependencies (if needed)"
echo "  3. Build Zed, CLI, and remote_server"
echo "  4. Create ready-to-use binaries"
echo ""
read -p "Continue? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Starting build process..."
echo ""

# Make build script executable if it isn't
chmod +x build-local.sh

# Run the build
./build-local.sh

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Build Complete! Here's what to do next:                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Run Zed:"
echo "  ./zed-local-build/zed"
echo ""
echo "Run CLI:"
echo "  ./zed-local-build/zed-cli --help"
echo ""
echo "See BUILD_LOCALLY.md for more information!"
echo ""
