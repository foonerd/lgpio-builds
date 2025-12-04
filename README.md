# lgpio-builds

Docker-based cross-compilation build system for lgpio (lg) library.

Produces Debian packages containing static library and headers for use in
dependent projects (e.g., allo-relay-builds).

## Overview

lgpio is a C library for Linux Single Board Computers which allows control
of GPIO, I2C, SPI, and serial interfaces. It is the recommended replacement
for WiringPi on Raspberry Pi OS Bookworm and later.

- **Source**: https://github.com/joan2937/lg
- **Author**: joan2937
- **Version**: 0.2.2

## Output

Builds produce Debian packages for each architecture:

| Architecture | Platform | Packages |
|--------------|----------|----------|
| armv6 | Pi Zero/1 | libfn-lgpio, libfn-lgpio-dev |
| armhf | Pi 2/3 | libfn-lgpio, libfn-lgpio-dev |
| arm64 | Pi 4/5 | libfn-lgpio, libfn-lgpio-dev |
| amd64 | x86_64 | libfn-lgpio, libfn-lgpio-dev |

Package contents:
- `libfn-lgpio`: Static library (`/usr/lib/<triplet>/libfn-lgpio.a`)
- `libfn-lgpio-dev`: Headers and pkg-config (`/usr/include/lgpio.h`, `/usr/lib/<triplet>/pkgconfig/libfn-lgpio.pc`)

## Requirements

- Docker with multi-architecture support (buildx)
- QEMU for cross-architecture emulation

Setup on Debian/Ubuntu:
```bash
sudo apt-get install docker.io qemu-user-static binfmt-support
sudo systemctl enable --now docker
```

## Source Setup

Download the lgpio source tarball before building:

```bash
cd package-sources
wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz -O lg-0.2.2.tar.gz
```

Verify SHA256:
```bash
sha256sum lg-0.2.2.tar.gz
```

## Building

Build all architectures:
```bash
./build-matrix.sh
```

Build single architecture:
```bash
./docker/run-docker-lgpio.sh arm64
./docker/run-docker-lgpio.sh armhf --verbose
```

## Output Structure

```
out/
  armv6/
    libfn-lgpio_0.2.2-1_armhf.deb
    libfn-lgpio-dev_0.2.2-1_armhf.deb
  armhf/
    libfn-lgpio_0.2.2-1_armhf.deb
    libfn-lgpio-dev_0.2.2-1_armhf.deb
  arm64/
    libfn-lgpio_0.2.2-1_arm64.deb
    libfn-lgpio-dev_0.2.2-1_arm64.deb
  amd64/
    libfn-lgpio_0.2.2-1_amd64.deb
    libfn-lgpio-dev_0.2.2-1_amd64.deb
```

## Usage in Dependent Projects

Install DEBs in Docker container:
```bash
dpkg -i /debs/*.deb
```

Link against static library:
```bash
gcc -o myapp myapp.c $(pkg-config --cflags --libs libfn-lgpio)
```

Or manually:
```bash
gcc -o myapp myapp.c -I/usr/include -L/usr/lib/<triplet> -lfn-lgpio
```

## Cleaning

Remove all build artifacts:
```bash
./clean-all.sh
```

## License

Build scripts: MIT License
lgpio library: Public Domain (joan2937)
