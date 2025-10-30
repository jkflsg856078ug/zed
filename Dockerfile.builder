# Zed Builder Container
# This creates a reproducible build environment for Zed
#
# Usage:
#   docker build -f Dockerfile.builder -t zed-builder .
#   docker run -v $(pwd)/build-output:/output zed-builder

FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH=/usr/local/cargo/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libasound2-dev \
    libfontconfig-dev \
    libwayland-dev \
    libx11-xcb-dev \
    libxkbcommon-x11-dev \
    libssl-dev \
    libzstd-dev \
    libvulkan1 \
    libgit2-dev \
    make \
    cmake \
    clang \
    jq \
    git \
    curl \
    gettext-base \
    elfutils \
    libsqlite3-dev \
    musl-tools \
    musl-dev \
    build-essential \
    pkg-config \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# Add musl target for static remote_server
RUN rustup target add x86_64-unknown-linux-musl

# Set working directory
WORKDIR /zed

# Copy source code
COPY . .

# Build script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Building Zed + CLI..."\n\
cargo build --release --package zed --package cli\n\
\n\
echo "Building Remote Server (static)..."\n\
export RUSTFLAGS="-C target-feature=+crt-static"\n\
cargo build --release --target x86_64-unknown-linux-musl --package remote_server\n\
\n\
echo "Packaging binaries..."\n\
mkdir -p /output\n\
cp target/release/zed /output/\n\
cp target/release/cli /output/zed-cli\n\
cp target/x86_64-unknown-linux-musl/release/remote_server /output/\n\
chmod +x /output/*\n\
\n\
cd /output\n\
tar -czf zed-docker-build.tar.gz zed zed-cli remote_server\n\
\n\
echo ""\n\
echo "✓ Build complete!"\n\
echo "Binaries are in /output/"\n\
ls -lh /output/\n\
' > /build.sh && chmod +x /build.sh

CMD ["/build.sh"]
