#!/bin/bash

# Binkd Build Script
# This script builds static Binkd binaries

set -e

echo "=== Building Binkd ==="

# Determine architecture for output naming
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    ARCH_NAME="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="x86_64"
else
    ARCH_NAME="$ARCH"
fi

echo "Building for architecture: $ARCH_NAME"

# Ensure we have the Binkd source
if [ ! -d "/build/binkd" ]; then
    echo "Error: Binkd source directory not found!"
    exit 1
fi

cd /build/binkd

# Set up static linking environment
export LDFLAGS="-static -s"
export CFLAGS="-O2 -static"
export CXXFLAGS="-O2 -static"

echo "Configuring Binkd build..."

# According to README.md, copy files from mkfls/unix/ to root
if [ -d "mkfls/unix" ]; then
    echo "Copying Unix build files from mkfls/unix/..."
    cp mkfls/unix/* .
    echo "Files copied successfully"
else
    echo "Error: mkfls/unix/ directory not found"
    echo "Available mkfls directories:"
    ls -la mkfls/ || echo "mkfls directory not found"
    exit 1
fi

# Check if we now have a configure script
if [ -f "configure" ]; then
    echo "Running configure script with static linking options..."
    ./configure --enable-static --disable-shared \
                --disable-rpath \
                LDFLAGS="$LDFLAGS" \
                CFLAGS="$CFLAGS"
elif [ -f "Makefile" ] || [ -f "makefile" ]; then
    echo "Using existing Makefile/makefile"
    # Modify for static linking
    if [ -f "Makefile" ]; then
        MAKEFILE="Makefile"
    else
        MAKEFILE="makefile"
    fi
    
    # Update CFLAGS and LDFLAGS for static linking
    sed -i "s/^CFLAGS[[:space:]]*=.*/CFLAGS = $CFLAGS/" "$MAKEFILE" || echo "CFLAGS = $CFLAGS" >> "$MAKEFILE"
    sed -i "s/^LDFLAGS[[:space:]]*=.*/LDFLAGS = $LDFLAGS/" "$MAKEFILE" || echo "LDFLAGS = $LDFLAGS" >> "$MAKEFILE"
    
    echo "Modified $MAKEFILE for static linking"
else
    echo "Error: No configure script or Makefile found after copying unix files"
    echo "Available files after copy:"
    ls -la
    exit 1
fi

# Build Binkd
echo "Building Binkd..."
make clean || true  # Clean any previous builds, ignore errors
make

# Create output directory for this architecture
mkdir -p /output/binkd/$ARCH_NAME

# Find and copy the binary
echo "Looking for Binkd binary..."
if [ -f "binkd" ]; then
    cp binkd "/output/binkd/$ARCH_NAME/"
    echo "Copied binkd to /output/binkd/$ARCH_NAME/"
elif [ -f "src/binkd" ]; then
    cp src/binkd "/output/binkd/$ARCH_NAME/"
    echo "Copied binkd to /output/binkd/$ARCH_NAME/"
else
    # Search for the binary
    binkd_path=$(find . -name "binkd" -type f -executable | head -1)
    if [ -n "$binkd_path" ]; then
        cp "$binkd_path" "/output/binkd/$ARCH_NAME/"
        echo "Found and copied binkd from $binkd_path to /output/binkd/$ARCH_NAME/"
    else
        echo "Error: Binkd binary not found!"
        echo "Build output:"
        find . -name "*binkd*" -type f
        exit 1
    fi
fi

# Also look for any configuration tools or utilities
for util in binkdcfg mkfls; do
    if [ -f "$util" ]; then
        cp "$util" "/output/binkd/$ARCH_NAME/"
        echo "Copied $util to /output/binkd/$ARCH_NAME/"
    fi
done

# Verify the binary is static
echo "Verifying static linking..."
for binary in /output/binkd/$ARCH_NAME/*; do
    if [ -f "$binary" ]; then
        echo "Checking $binary:"
        file "$binary"
        echo "Dependencies:"
        ldd "$binary" 2>/dev/null | head -5 || echo "  (statically linked or no dynamic dependencies shown)"
        echo ""
    fi
done

echo "Binkd build complete!"
echo "Binaries available in: /output/binkd/$ARCH_NAME/"
ls -la /output/binkd/$ARCH_NAME/ || true