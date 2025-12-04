#!/bin/bash
# lgpio-builds scripts/build-lgpio.sh
# Build script for lgpio library DEBs (runs inside Docker container)

set -e

LGPIO_VERSION="0.2.2"
PKG_VERSION="${LGPIO_VERSION}-1"

echo "[+] Starting lgpio build"
echo "[+] Architecture: $ARCH"
echo "[+] Library path: $LIB_PATH"
echo "[+] DEB architecture: $DEB_ARCH"
echo "[+] Extra CFLAGS: $EXTRA_CFLAGS"
echo "[+] Package version: $PKG_VERSION"
echo ""

# Directories
BUILD_BASE="/build"
SOURCE_DIR="$BUILD_BASE/lg-source"
PKG_LIB_DIR="$BUILD_BASE/pkg-lib"
PKG_DEV_DIR="$BUILD_BASE/pkg-dev"
OUTPUT_DIR="$BUILD_BASE/output"

mkdir -p "$SOURCE_DIR"
mkdir -p "$PKG_LIB_DIR"
mkdir -p "$PKG_DEV_DIR"
mkdir -p "$OUTPUT_DIR"

#
# Step 1: Extract lgpio source
#
echo "[+] Extracting lgpio source..."

cd "$SOURCE_DIR"
tar -xzf /build/package-sources/lg-${LGPIO_VERSION}.tar.gz --strip-components=1

echo "[+] Source extracted"
ls -la

#
# Step 2: Build lgpio as static library
#
echo ""
echo "[+] Building lgpio..."

# Apply architecture-specific flags
if [ -n "$EXTRA_CFLAGS" ]; then
  export CFLAGS="$EXTRA_CFLAGS -fPIC -O2"
else
  export CFLAGS="-fPIC -O2"
fi

# Build the library
# lgpio uses a simple Makefile, we need to modify it for static library
make CFLAGS="$CFLAGS" -j$(nproc)

echo "[+] Build complete"
ls -la *.so* *.a 2>/dev/null || true

# Create static library if not already created
if [ ! -f liblgpio.a ]; then
  echo "[+] Creating static library from object files..."
  ar rcs liblgpio.a lgpio.o lgDbg.o lgHdl.o lgGpio.o lgI2C.o lgPthAlerts.o \
    lgPthTx.o lgSerial.o lgSPI.o lgThread.o lgUtil.o 2>/dev/null || \
  ar rcs liblgpio.a *.o
fi

echo "[+] Static library:"
ls -la liblgpio.a

#
# Step 3: Create library package (libfn-lgpio)
#
echo ""
echo "[+] Creating libfn-lgpio package..."

PKG_LIB_NAME="libfn-lgpio_${PKG_VERSION}_${DEB_ARCH}"
PKG_LIB_ROOT="$PKG_LIB_DIR/$PKG_LIB_NAME"

mkdir -p "$PKG_LIB_ROOT/DEBIAN"
mkdir -p "$PKG_LIB_ROOT$LIB_PATH"

# Copy static library with fn- prefix
cp liblgpio.a "$PKG_LIB_ROOT$LIB_PATH/libfn-lgpio.a"

# Create control file
cat > "$PKG_LIB_ROOT/DEBIAN/control" << EOF
Package: libfn-lgpio
Version: $PKG_VERSION
Section: libs
Priority: optional
Architecture: $DEB_ARCH
Maintainer: Volumio <info@volumio.com>
Description: lgpio static library for GPIO/I2C/SPI control
 Static library build of lgpio (lg) for Linux SBCs.
 Provides GPIO, I2C, SPI, and serial interface control.
 This is a custom build with fn- prefix to avoid conflicts.
EOF

# Build the package
cd "$PKG_LIB_DIR"
fakeroot dpkg-deb --build "$PKG_LIB_NAME"
cp "${PKG_LIB_NAME}.deb" "$OUTPUT_DIR/"

echo "[+] Created: ${PKG_LIB_NAME}.deb"

#
# Step 4: Create dev package (libfn-lgpio-dev)
#
echo ""
echo "[+] Creating libfn-lgpio-dev package..."

PKG_DEV_NAME="libfn-lgpio-dev_${PKG_VERSION}_${DEB_ARCH}"
PKG_DEV_ROOT="$PKG_DEV_DIR/$PKG_DEV_NAME"

mkdir -p "$PKG_DEV_ROOT/DEBIAN"
mkdir -p "$PKG_DEV_ROOT/usr/include"
mkdir -p "$PKG_DEV_ROOT$LIB_PATH/pkgconfig"

# Copy header files
cp "$SOURCE_DIR/lgpio.h" "$PKG_DEV_ROOT/usr/include/"

# Create pkg-config file
cat > "$PKG_DEV_ROOT$LIB_PATH/pkgconfig/libfn-lgpio.pc" << EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=$LIB_PATH
includedir=\${prefix}/include

Name: libfn-lgpio
Description: lgpio library for GPIO/I2C/SPI control on Linux SBCs
Version: $LGPIO_VERSION
Libs: -L\${libdir} -lfn-lgpio -lpthread
Cflags: -I\${includedir}
EOF

# Create control file
cat > "$PKG_DEV_ROOT/DEBIAN/control" << EOF
Package: libfn-lgpio-dev
Version: $PKG_VERSION
Section: libdevel
Priority: optional
Architecture: $DEB_ARCH
Depends: libfn-lgpio (= $PKG_VERSION)
Maintainer: Volumio <info@volumio.com>
Description: lgpio development files for GPIO/I2C/SPI control
 Development headers and pkg-config file for lgpio (lg) library.
 Provides GPIO, I2C, SPI, and serial interface control.
 This is a custom build with fn- prefix to avoid conflicts.
EOF

# Build the package
cd "$PKG_DEV_DIR"
fakeroot dpkg-deb --build "$PKG_DEV_NAME"
cp "${PKG_DEV_NAME}.deb" "$OUTPUT_DIR/"

echo "[+] Created: ${PKG_DEV_NAME}.deb"

#
# Step 5: Verify packages
#
echo ""
echo "[+] Verifying packages..."

cd "$OUTPUT_DIR"
for deb in *.deb; do
  echo "  $deb:"
  dpkg-deb --info "$deb" | grep -E "Package|Version|Architecture"
  echo "  Contents:"
  dpkg-deb --contents "$deb" | head -10
  echo ""
done

echo "[+] Build complete"
ls -lh "$OUTPUT_DIR"/*.deb
