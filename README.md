# lgpio-builds

Docker-based build system for lgpio library DEBs targeting Volumio 4.x (Bookworm).

## Overview

Builds the lg library (lgpio) as static library DEBs for use as a build dependency.
Follows Volumio multistrap architecture naming conventions.

## Output Packages

- libfn-lgpio0 - Static library
- libfn-lgpio-dev - Development files (headers, pkg-config)

## Prerequisites

1. Docker with buildx and QEMU for cross-compilation
2. Download lg source tarball

## Setup

```bash
cd package-sources
wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz -O lg-0.2.2.tar.gz
```

## Build Commands

Build all architectures for Volumio:
```bash
./build-matrix.sh --volumio
```

Build single architecture:
```bash
./scripts/extract.sh
./docker/run-docker-lgpio.sh lgpio arm64 volumio --verbose
```

## Output Files

With --volumio flag:
```
out/armv6/libfn-lgpio0_0.2.2-1_arm.deb
out/armv6/libfn-lgpio-dev_0.2.2-1_arm.deb
out/armhf/libfn-lgpio0_0.2.2-1_armv7.deb
out/armhf/libfn-lgpio-dev_0.2.2-1_armv7.deb
out/arm64/libfn-lgpio0_0.2.2-1_armv8.deb
out/arm64/libfn-lgpio-dev_0.2.2-1_armv8.deb
out/amd64/libfn-lgpio0_0.2.2-1_x64.deb
out/amd64/libfn-lgpio-dev_0.2.2-1_x64.deb
```

## Architecture Mapping

| Build Arch | Docker Platform | Volumio Suffix |
|------------|-----------------|----------------|
| armv6      | linux/arm/v7    | _arm.deb       |
| armhf      | linux/arm/v7    | _armv7.deb     |
| arm64      | linux/arm64     | _armv8.deb     |
| amd64      | linux/amd64     | _x64.deb       |

## License

MIT License. lgpio is public domain.
