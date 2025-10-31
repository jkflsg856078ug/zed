#!/usr/bin/env bash
#
# Vendor all Cargo dependencies for offline builds
#

set -e

echo "Vendoring all Cargo dependencies..."
echo "This will download all dependencies and store them locally."
echo ""

# Create vendor directory
mkdir -p vendor

# Vendor dependencies
echo "Running cargo vendor..."
cargo vendor vendor > .cargo/config.toml.vendor

echo ""
echo "✓ Dependencies vendored to ./vendor/"
echo ""
echo "To use vendored dependencies, run:"
echo "  cp .cargo/config.toml.vendor .cargo/config.toml"
echo ""
echo "To revert to online dependencies:"
echo "  rm .cargo/config.toml"
echo ""
echo "Note: The vendor directory is ~2-3GB"
