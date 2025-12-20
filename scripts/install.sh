#!/bin/bash
set -e

# wg-lite-hop installer
# Fetches the latest release and runs setup

echo "=== wg-lite-hop Installer ==="

# Get latest release tag from GitHub API
LATEST_TAG=$(curl -s https://api.github.com/repos/ernvk23/wg-lite-hop/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "Error: Could not fetch latest release tag"
    echo "Falling back to v2.1"
    LATEST_TAG="v2.1"
fi

echo "Installing $LATEST_TAG..."

# Create directory and download
mkdir -p ~/wg-lite-hop
cd ~/wg-lite-hop
curl -L "https://github.com/ernvk23/wg-lite-hop/archive/refs/tags/${LATEST_TAG}.tar.gz" | tar --strip-components=1 -xz --warning=none
chmod +x ./scripts/setup.sh

echo "Starting setup..."
sudo ./scripts/setup.sh