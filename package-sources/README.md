# Package Sources

This directory contains the source tarball for lgpio (lg library).

## Current Source

- **lg-0.2.2.tar.gz**
  - Version: 0.2.2
  - Release Date: 2023-05-03
  - Source: https://github.com/joan2937/lg/releases/tag/v0.2.2
  - SHA256: (verify after download)

## Download

```bash
wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz -O lg-0.2.2.tar.gz
```

## Updating Source

To update to a newer version:

1. Download the new release tarball from GitHub
2. Replace the tarball in this directory
3. Update the version references in:
   - scripts/build-lgpio.sh (LGPIO_VERSION)
   - docker/run-docker-lgpio.sh (version check)
   - README.md (root)
   - This file

## Library Features

lgpio provides:
- GPIO read/write (single and group)
- Software timed PWM and waves
- GPIO callbacks and alerts
- I2C wrapper
- SPI wrapper
- Serial link wrapper

## License

lgpio is released into the public domain by joan2937.
