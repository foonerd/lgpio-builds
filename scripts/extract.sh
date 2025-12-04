#!/bin/bash
set -e

if [[ ! -d "package-sources" ]]; then
  echo "Error: Run from repository root"
  exit 1
fi

SOURCE_TAR="package-sources/lg-0.2.2.tar.gz"

if [[ ! -f "$SOURCE_TAR" ]]; then
  echo "Error: $SOURCE_TAR not found"
  echo "Download from: https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz"
  exit 1
fi

DEST_DIR="build/lgpio/source"

echo "[+] Cleaning $DEST_DIR"
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

echo "[+] Extracting lg source"
tar -xzf "$SOURCE_TAR" -C /tmp/
# Handle both lg-0.2.2 and lg-master directory names
if [[ -d "/tmp/lg-0.2.2" ]]; then
  mv /tmp/lg-0.2.2/* "$DEST_DIR"/
  rm -rf /tmp/lg-0.2.2
elif [[ -d "/tmp/lg-master" ]]; then
  mv /tmp/lg-master/* "$DEST_DIR"/
  rm -rf /tmp/lg-master
else
  # Find extracted directory
  EXTRACTED=$(find /tmp -maxdepth 1 -type d -name "lg*" | head -1)
  if [[ -n "$EXTRACTED" ]]; then
    mv "$EXTRACTED"/* "$DEST_DIR"/
    rm -rf "$EXTRACTED"
  else
    echo "Error: Could not find extracted lg directory"
    exit 1
  fi
fi

echo "[+] Listing extracted files"
ls -la "$DEST_DIR"/*.c 2>/dev/null || echo "No .c files in root"
ls -la "$DEST_DIR"/*.h 2>/dev/null || echo "No .h files in root"

echo "[+] Creating debian packaging for fooNerd"

cd "$DEST_DIR"
mkdir -p debian

# Find all lg*.c source files - library modules (exclude rg*.c daemon/client files)
LGPIO_SRCS=$(ls lg*.c 2>/dev/null | tr '\n' ' ')
if [[ -z "$LGPIO_SRCS" ]]; then
  echo "Error: No lg*.c files found in extracted source"
  echo "Directory contents:"
  ls -la
  exit 1
fi

echo "[+] Found library source files: $LGPIO_SRCS"

# Check for header file
if [[ ! -f "lgpio.h" ]]; then
  echo "Error: lgpio.h not found in extracted source"
  exit 1
fi

# Create debian/control
cat > debian/control << 'EOF'
Source: foonerd-lgpio
Section: libs
Priority: optional
Maintainer: fooNerd (Just a Nerd) <nerd@foonerd.com>
Build-Depends: debhelper (>= 10~)
Standards-Version: 4.1.4
Homepage: https://github.com/foonerd/lgpio-builds

Package: libfn-lgpio0
Section: libs
Architecture: any
Depends: ${misc:Depends}
Description: fooNerd lgpio library (static library)
 GPIO library for Raspberry Pi using /dev/gpiochip interface.
 Custom build by fooNerd for Volumio integration.
 .
 This package contains the static library.

Package: libfn-lgpio-dev
Section: libdevel
Architecture: any
Depends: libfn-lgpio0 (= ${binary:Version}),
         ${misc:Depends}
Description: fooNerd lgpio library (development files)
 GPIO library for Raspberry Pi using /dev/gpiochip interface.
 Custom build by fooNerd for Volumio integration.
 .
 This package contains development files.
EOF

# Create debian/rules - compile all .c files in root
cat > debian/rules << 'EOF'
#!/usr/bin/make -f
DEB_HOST_MULTIARCH ?= $(shell dpkg-architecture -qDEB_HOST_MULTIARCH)
export DEB_HOST_MULTIARCH

# Find all lg*.c source files (library modules, exclude rg*.c daemon/client files)
LGPIO_SRCS := $(wildcard lg*.c)
LGPIO_OBJS := $(LGPIO_SRCS:.c=.o)

%:
	dh $@

override_dh_auto_build:
	@echo "Building from sources: $(LGPIO_SRCS)"
	for src in $(LGPIO_SRCS); do \
		echo "Compiling $$src"; \
		$(CC) $(CFLAGS) -fPIC -c -o $${src%.c}.o $$src; \
	done
	ar rcs libfn-lgpio.a $(LGPIO_OBJS)
	ranlib libfn-lgpio.a
	@echo "Created libfn-lgpio.a with objects: $(LGPIO_OBJS)"

override_dh_auto_install:
	mkdir -p debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)
	mkdir -p debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig
	mkdir -p debian/tmp/usr/include
	# Install static library
	cp libfn-lgpio.a debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/
	# Copy header
	cp lgpio.h debian/tmp/usr/include/
	# Create pkg-config file
	echo 'prefix=/usr' > debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'exec_prefix=$${prefix}' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'libdir=$${prefix}/lib/$(DEB_HOST_MULTIARCH)' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'includedir=$${prefix}/include' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo '' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'Name: libfn-lgpio' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'Description: fooNerd lgpio GPIO library' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'Version: 0.2.2' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'Libs: -L$${libdir} -lfn-lgpio -lpthread' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc
	echo 'Cflags: -I$${includedir}' >> debian/tmp/usr/lib/$(DEB_HOST_MULTIARCH)/pkgconfig/libfn-lgpio.pc

override_dh_auto_clean:
	rm -f *.o libfn-lgpio.a || true

override_dh_fixperms:
	dh_fixperms || true
EOF

chmod +x debian/rules

# Create debian/compat
echo "10" > debian/compat

# Create install files
cat > debian/libfn-lgpio0.install << 'EOF'
usr/lib/*/libfn-lgpio.a
EOF

cat > debian/libfn-lgpio-dev.install << 'EOF'
usr/include/lgpio.h
usr/lib/*/pkgconfig/libfn-lgpio.pc
EOF

# Create changelog
cat > debian/changelog << 'EOF'
foonerd-lgpio (0.2.2-1) bookworm; urgency=medium

  * Initial fooNerd release
  * Custom build from joan2937/lg source
  * Static library: libfn-lgpio.a
  * For Volumio plugin builds

 -- fooNerd (Just a Nerd) <nerd@foonerd.com>  Sat, 23 Nov 2024 10:00:00 +0000
EOF

# Create source/format
mkdir -p debian/source
echo "3.0 (native)" > debian/source/format

cd - > /dev/null

echo "[OK] Source prepared in $DEST_DIR"
