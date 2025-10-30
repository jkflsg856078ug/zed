# Building Zed Locally - Complete Guide

This guide will help you build Zed with remote MCP server support on your local machine.

## 🚀 Quick Start (Recommended)

### Option 1: Using the Build Script (Linux/macOS)

```bash
# Clone the repository
git clone https://github.com/jkflsg856078ug/zed.git
cd zed

# Checkout the rebased branch with MCP support
git checkout claude/rebase-fork-onto-main-011CUeAqoXCeCiFW5vZdkxCM

# Make the build script executable
chmod +x build-local.sh

# Run the build (this will install dependencies and build everything)
./build-local.sh
```

**That's it!** The script will:
- ✅ Check for required dependencies
- ✅ Install missing dependencies (requires sudo on Linux)
- ✅ Build Zed, CLI, and remote_server
- ✅ Create a `zed-local-build/` directory with all binaries
- ✅ Create a `.tar.gz` archive for easy distribution

### Option 2: Using Docker (Works Everywhere)

```bash
# Clone the repository
git clone https://github.com/jkflsg856078ug/zed.git
cd zed
git checkout claude/rebase-fork-onto-main-011CUeAqoXCeCiFW5vZdkxCM

# Build the Docker image
docker build -f Dockerfile.builder -t zed-builder .

# Run the build
mkdir -p build-output
docker run -v $(pwd)/build-output:/output zed-builder

# Your binaries are now in build-output/
ls -lh build-output/
```

---

## 📋 Build Script Options

```bash
./build-local.sh [OPTIONS]

Options:
  --debug       Build in debug mode (faster compile, slower runtime)
  --skip-deps   Skip dependency installation check
  --clean       Clean build (removes target directory first)
  --help, -h    Show help message

Examples:
  ./build-local.sh              # Standard release build
  ./build-local.sh --debug      # Faster debug build for testing
  ./build-local.sh --clean      # Start from scratch
  ./build-local.sh --skip-deps  # Don't check/install dependencies
```

---

## 🛠 Manual Build Instructions

If you prefer to build manually or the script doesn't work:

### Prerequisites

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update && sudo apt-get install -y \
    gcc g++ libasound2-dev libfontconfig-dev libwayland-dev \
    libx11-xcb-dev libxkbcommon-x11-dev libssl-dev libzstd-dev \
    libvulkan1 libgit2-dev make cmake clang jq git curl \
    gettext-base elfutils libsqlite3-dev musl-tools \
    musl-dev build-essential pkg-config
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install -y \
    musl-gcc gcc clang cmake alsa-lib-devel fontconfig-devel \
    wayland-devel libxcb-devel libxkbcommon-x11-devel \
    openssl-devel libzstd-devel vulkan-loader sqlite-devel \
    jq git tar g++
```

#### macOS
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Rust (All Platforms)
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add musl target for static remote_server (Linux only)
rustup target add x86_64-unknown-linux-musl
```

### Build Steps

```bash
# 1. Clone and checkout the branch
git clone https://github.com/jkflsg856078ug/zed.git
cd zed
git checkout claude/rebase-fork-onto-main-011CUeAqoXCeCiFW5vZdkxCM

# 2. Build Zed and CLI
cargo build --release --package zed --package cli

# 3. Build remote_server (Linux - static binary)
export RUSTFLAGS="-C target-feature=+crt-static"
cargo build --release --target x86_64-unknown-linux-musl --package remote_server

# Or macOS
cargo build --release --package remote_server

# 4. Your binaries are ready!
# Linux:
#   - target/release/zed
#   - target/release/cli
#   - target/x86_64-unknown-linux-musl/release/remote_server
#
# macOS:
#   - target/release/zed
#   - target/release/cli
#   - target/release/remote_server
```

---

## 📦 What Gets Built

After a successful build, you'll have three binaries:

### 1. **zed** - The main Zed editor
- Full-featured code editor
- **NEW**: Support for remote MCP (Model Context Protocol) servers
- **NEW**: HTTP transport for remote context servers
- **NEW**: Bearer token authentication support

### 2. **cli** (zed-cli) - Command line interface
- Open files/directories in Zed from terminal
- Project management from command line

### 3. **remote_server** - Remote development server
- Enables remote development over SSH
- **NEW**: Built with MCP context server support
- Static binary (Linux) - works on any Linux distribution

---

## 🧪 Testing the Build

### Test Zed
```bash
./zed-local-build/zed --version
./zed-local-build/zed /path/to/project
```

### Test CLI
```bash
./zed-local-build/zed-cli --help
```

### Test Remote Server
```bash
./zed-local-build/remote_server --help
```

### Test Remote MCP Server (NEW Feature!)

Create a test config file `~/.config/zed/settings.json`:
```json
{
  "context_servers": {
    "github-mcp": {
      "url": "https://your-mcp-server.com/mcp",
      "auth": {
        "bearer": {
          "token": "your-token-here"
        }
      }
    }
  }
}
```

---

## ⚡ Performance Tips

### Faster Builds

1. **Use debug builds during development**
   ```bash
   ./build-local.sh --debug  # Much faster compile time
   ```

2. **Use mold linker (Linux)**
   ```bash
   sudo apt install mold  # Already in build script
   ```

3. **Increase parallel jobs**
   ```bash
   export CARGO_BUILD_JOBS=8  # Use 8 cores
   ```

### Build Times (Approximate)

On a typical modern system (8 cores, 16GB RAM):

| Build Type | First Build | Incremental |
|------------|-------------|-------------|
| Debug      | ~15-20 min  | ~2-5 min    |
| Release    | ~25-35 min  | ~5-10 min   |

---

## 🐛 Troubleshooting

### Common Issues

#### "command not found: cargo"
```bash
# Add Rust to your PATH
source $HOME/.cargo/env
```

#### "failed to fetch" or network errors
```bash
# Clean and rebuild
cargo clean
./build-local.sh
```

#### Missing system libraries
```bash
# Run the dependency installer
./script/linux  # Linux
# or
./build-local.sh  # Automatically installs deps
```

#### Build runs out of memory
```bash
# Limit parallel jobs
export CARGO_BUILD_JOBS=2
./build-local.sh
```

#### Windows builds
```powershell
# Use Windows-specific build script (coming soon)
# Or use WSL2 with the Linux instructions
```

---

## 📚 Additional Resources

- **Zed Documentation**: https://zed.dev/docs
- **PR #39021**: Remote MCP server support
- **Repository**: https://github.com/jkflsg856078ug/zed
- **Build Issues**: Open an issue on GitHub

---

## 🎯 What's Special About This Build

This build includes **PR #39021** which adds:

✨ **Remote MCP Server Support**
- Connect to Model Context Protocol servers over HTTP/HTTPS
- Bearer token authentication
- API key authentication
- Custom header authentication
- Session management
- Server-Sent Events (SSE) streaming

This allows Zed to connect to remote AI context servers like GitHub Copilot, Claude, GPT, and custom MCP implementations!

---

## 🚀 Quick Reference Card

```bash
# One-line build (recommended)
git clone https://github.com/jkflsg856078ug/zed.git && \
cd zed && \
git checkout claude/rebase-fork-onto-main-011CUeAqoXCeCiFW5vZdkxCM && \
chmod +x build-local.sh && \
./build-local.sh

# Or with Docker
docker build -f Dockerfile.builder -t zed-builder . && \
mkdir -p build-output && \
docker run -v $(pwd)/build-output:/output zed-builder

# Run Zed
./zed-local-build/zed
```

---

**Happy Building! 🎉**

If you encounter any issues, please open an issue on GitHub with:
- Your OS and version
- The error message
- Output of `./build-local.sh --help`
