#!/usr/bin/env bash
#
# Local Build Script for Zed Fork with Remote MCP Server Support
# This script will build Zed binaries locally on your machine
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Zed Fork - Local Build Script${NC}"
echo -e "${BLUE}  Building: Zed + CLI + Remote Server with MCP Support${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Parse arguments
BUILD_TYPE="release"
SKIP_DEPS=false
CLEAN_BUILD=false
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            HELP=true
            shift
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo "Usage: ./build-local.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --debug       Build in debug mode (faster compile, slower runtime)"
    echo "  --skip-deps   Skip dependency installation check"
    echo "  --clean       Clean build (removes target directory)"
    echo "  --help, -h    Show this help message"
    echo
    echo "Examples:"
    echo "  ./build-local.sh              # Build release binaries"
    echo "  ./build-local.sh --debug      # Build debug binaries"
    echo "  ./build-local.sh --clean      # Clean build from scratch"
    exit 0
fi

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    echo "This script supports Linux and macOS only."
    exit 1
fi

echo -e "${GREEN}✓${NC} Detected OS: ${YELLOW}$OS${NC}"

# Check for Rust - auto-install if missing
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Rust is not installed. Installing Rust..."
    echo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo env
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}✗${NC} Rust installation failed!"
        echo "Please install manually from: https://rustup.rs/"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Rust installed successfully"
fi

# Ensure rustup is available
if ! command -v rustup &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} rustup not found. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
fi

RUST_VERSION=$(rustc --version)
echo -e "${GREEN}✓${NC} Rust: ${YELLOW}$RUST_VERSION${NC}"

# Install system dependencies
if [ "$SKIP_DEPS" = false ]; then
    echo
    echo -e "${BLUE}Checking system dependencies...${NC}"

    if [ "$OS" = "linux" ]; then
        # Check if running as root or with sudo
        if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
            echo -e "${RED}✗${NC} This script requires sudo for dependency installation"
            echo "Either run as root or install sudo"
            exit 1
        fi

        SUDO_CMD=""
        if [ "$EUID" -ne 0 ]; then
            SUDO_CMD="sudo"
        fi

        # Use the official script/linux
        if [ -f "./script/linux" ]; then
            echo -e "${YELLOW}Running official dependency installer...${NC}"
            ./script/linux
        else
            echo -e "${YELLOW}Installing dependencies manually...${NC}"

            if command -v apt-get &> /dev/null; then
                $SUDO_CMD apt-get update
                $SUDO_CMD apt-get install -y \
                    gcc g++ libasound2-dev libfontconfig-dev libwayland-dev \
                    libx11-xcb-dev libxkbcommon-x11-dev libssl-dev libzstd-dev \
                    libvulkan1 libgit2-dev make cmake clang jq git curl \
                    gettext-base elfutils libsqlite3-dev musl-tools \
                    musl-dev build-essential pkg-config
            elif command -v dnf &> /dev/null; then
                $SUDO_CMD dnf install -y \
                    musl-gcc gcc clang cmake alsa-lib-devel fontconfig-devel \
                    wayland-devel libxcb-devel libxkbcommon-x11-devel \
                    openssl-devel libzstd-devel vulkan-loader sqlite-devel \
                    jq git tar g++ perl-FindBin perl-IPC-Cmd
            else
                echo -e "${RED}Unsupported package manager. Please install dependencies manually.${NC}"
                echo "See: ./script/linux for required packages"
                exit 1
            fi
        fi

        echo -e "${GREEN}✓${NC} Dependencies installed"

        # Add musl target for remote_server - check if already installed
        echo -e "${YELLOW}Checking musl target for static remote_server build...${NC}"
        if ! rustup target list --installed | grep -q "x86_64-unknown-linux-musl"; then
            echo -e "${YELLOW}Installing musl target...${NC}"
            rustup target add x86_64-unknown-linux-musl
            echo -e "${GREEN}✓${NC} musl target installed"
        else
            echo -e "${GREEN}✓${NC} musl target already installed"
        fi

    elif [ "$OS" = "macos" ]; then
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}✗${NC} Homebrew is not installed!"
            echo "Install from: https://brew.sh/"
            exit 1
        fi

        echo -e "${YELLOW}Installing macOS dependencies...${NC}"
        # Most dependencies on macOS are provided by Xcode Command Line Tools
        if ! xcode-select -p &> /dev/null; then
            echo "Installing Xcode Command Line Tools..."
            xcode-select --install
            echo "Please complete the Xcode installation and run this script again"
            exit 1
        fi
        echo -e "${GREEN}✓${NC} Dependencies ready"
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping dependency check (--skip-deps)"
fi

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    cargo clean
    echo -e "${GREEN}✓${NC} Clean complete"
fi

# Set RUSTFLAGS to allow unused variables
export RUSTFLAGS="${RUSTFLAGS:--A unused}"

# Build type
echo
if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "${BLUE}Building in RELEASE mode (optimized, slower compile)${NC}"
    BUILD_FLAG="--release"
    TARGET_DIR="target/release"
else
    echo -e "${BLUE}Building in DEBUG mode (faster compile, slower runtime)${NC}"
    BUILD_FLAG=""
    TARGET_DIR="target/debug"
fi

echo

# Build Zed and CLI
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1/3: Building Zed + CLI${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cargo build $BUILD_FLAG --package zed --package cli

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Zed + CLI built successfully"
else
    echo -e "${RED}✗${NC} Build failed"
    exit 1
fi

# Build remote_server
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2/3: Building Remote Server (static)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$OS" = "linux" ]; then
    # Build static binary for Linux
    export RUSTFLAGS="-C target-feature=+crt-static"

    if [ "$BUILD_TYPE" = "release" ]; then
        cargo build --release --target x86_64-unknown-linux-musl --package remote_server
        REMOTE_SERVER_BIN="target/x86_64-unknown-linux-musl/release/remote_server"
    else
        cargo build --target x86_64-unknown-linux-musl --package remote_server
        REMOTE_SERVER_BIN="target/x86_64-unknown-linux-musl/debug/remote_server"
    fi
else
    # macOS
    cargo build $BUILD_FLAG --package remote_server
    REMOTE_SERVER_BIN="$TARGET_DIR/remote_server"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Remote server built successfully"
else
    echo -e "${RED}✗${NC} Build failed"
    exit 1
fi

# Create output directory
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3/3: Packaging Binaries${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

OUTPUT_DIR="zed-local-build"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy binaries
if [ "$OS" = "linux" ]; then
    cp "$TARGET_DIR/zed" "$OUTPUT_DIR/"
    cp "$TARGET_DIR/cli" "$OUTPUT_DIR/zed-cli"
    cp "$REMOTE_SERVER_BIN" "$OUTPUT_DIR/remote_server"

    # Make them executable
    chmod +x "$OUTPUT_DIR/zed"
    chmod +x "$OUTPUT_DIR/zed-cli"
    chmod +x "$OUTPUT_DIR/remote_server"

    # Create archive
    tar -czf "zed-local-build-linux.tar.gz" -C "$OUTPUT_DIR" .
    echo -e "${GREEN}✓${NC} Created archive: ${YELLOW}zed-local-build-linux.tar.gz${NC}"

elif [ "$OS" = "macos" ]; then
    cp "$TARGET_DIR/zed" "$OUTPUT_DIR/"
    cp "$TARGET_DIR/cli" "$OUTPUT_DIR/zed-cli"
    cp "$REMOTE_SERVER_BIN" "$OUTPUT_DIR/remote_server"

    # Make them executable
    chmod +x "$OUTPUT_DIR/zed"
    chmod +x "$OUTPUT_DIR/zed-cli"
    chmod +x "$OUTPUT_DIR/remote_server"

    # Create archive
    tar -czf "zed-local-build-macos.tar.gz" -C "$OUTPUT_DIR" .
    echo -e "${GREEN}✓${NC} Created archive: ${YELLOW}zed-local-build-macos.tar.gz${NC}"
fi

# Print summary
echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ BUILD COMPLETE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "Built binaries are in: ${YELLOW}$OUTPUT_DIR/${NC}"
echo
echo "Available binaries:"
echo -e "  ${BLUE}zed${NC}              - Main Zed editor"
echo -e "  ${BLUE}zed-cli${NC}          - Command line interface"
echo -e "  ${BLUE}remote_server${NC}    - Remote development server (with MCP support)"
echo
echo "Binary locations:"
echo -e "  Zed:           ${YELLOW}$TARGET_DIR/zed${NC}"
echo -e "  CLI:           ${YELLOW}$TARGET_DIR/cli${NC}"
echo -e "  Remote Server: ${YELLOW}$REMOTE_SERVER_BIN${NC}"
echo
echo -e "Run Zed: ${YELLOW}./$OUTPUT_DIR/zed${NC}"
echo

if [ "$OS" = "linux" ]; then
    echo -e "Archive: ${YELLOW}zed-local-build-linux.tar.gz${NC}"
elif [ "$OS" = "macos" ]; then
    echo -e "Archive: ${YELLOW}zed-local-build-macos.tar.gz${NC}"
fi
echo
echo -e "${GREEN}Happy coding! 🚀${NC}"
