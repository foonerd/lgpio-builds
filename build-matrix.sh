#!/bin/bash
# lgpio-builds build-matrix.sh
# Build lgpio library DEBs for all architectures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERBOSE=""

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == "--verbose" ]]; then
    VERBOSE="--verbose"
  fi
done

echo "========================================"
echo "lgpio Build Matrix"
echo "========================================"
echo "Source: lg 0.2.2"
echo ""

# Check source tarball exists
if [ ! -f "package-sources/lg-0.2.2.tar.gz" ]; then
  echo "Error: package-sources/lg-0.2.2.tar.gz not found"
  echo ""
  echo "Download it first:"
  echo "  cd package-sources"
  echo "  wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz -O lg-0.2.2.tar.gz"
  exit 1
fi

# Build for all architectures
ARCHITECTURES=("armv6" "armhf" "arm64" "amd64")

for ARCH in "${ARCHITECTURES[@]}"; do
  echo ""
  echo "----------------------------------------"
  echo "Building for: $ARCH"
  echo "----------------------------------------"
  ./docker/run-docker-lgpio.sh "$ARCH" $VERBOSE
done

echo ""
echo "========================================"
echo "Build Matrix Complete"
echo "========================================"
echo ""
echo "Output structure:"
for ARCH in "${ARCHITECTURES[@]}"; do
  if [ -d "out/$ARCH" ]; then
    echo "  out/$ARCH/"
    ls -lh "out/$ARCH/"*.deb 2>/dev/null | awk '{printf "    %-40s %s\n", $9, $5}' || echo "    (no DEBs)"
  fi
done

echo ""
echo "Packages: libfn-lgpio, libfn-lgpio-dev"
