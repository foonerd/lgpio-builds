#!/bin/bash
set -e

ARCHS=("armv6" "armhf" "arm64" "amd64")
VOL_MODE=""
VERBOSE=""

for arg in "$@"; do
  case "$arg" in
    --volumio) VOL_MODE="volumio" ;;
    --verbose) VERBOSE="--verbose" ;;
  esac
done

for ARCH in "${ARCHS[@]}"; do
  echo ""
  echo "====================================="
  echo ">> Preparing clean source directory"
  echo "====================================="
  ./scripts/extract.sh
  echo ""
  echo "====================================="
  echo ">> Building for architecture: $ARCH"
  echo "====================================="
  ./docker/run-docker-lgpio.sh lgpio "$ARCH" "$VOL_MODE" "$VERBOSE"
done

echo ""
echo "[OK] All builds completed. Check the 'out/' directory for results."
