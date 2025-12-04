#!/bin/bash
# lgpio-builds clean-all.sh
# Clean all build artifacts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[+] Cleaning build artifacts..."

# Clean output directories
rm -f out/armv6/*.deb
rm -f out/armhf/*.deb
rm -f out/arm64/*.deb
rm -f out/amd64/*.deb

# Clean any temporary build directories
rm -rf build/

echo "[OK] Clean complete"
