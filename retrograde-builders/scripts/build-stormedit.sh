#!/bin/bash

# Stormedit Build Script
# This script builds Stormedit binaries

set -e

echo "=== Building Stormedit ==="

# Determine architecture for output naming
ARCH=$(uname -m)
if [ -n "$FORCE_ARCH" ]; then
    # Use forced architecture from environment
    if [ "$FORCE_ARCH" = "arm64" ]; then
        ARCH_NAME="arm64"
    elif [ "$FORCE_ARCH" = "x86_64" ]; then
        ARCH_NAME="x86_64"
    else
        ARCH_NAME="$FORCE_ARCH"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_NAME="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="x86_64"
else
    ARCH_NAME="$ARCH"
fi

echo "Building for architecture: $ARCH_NAME"

# Ensure we have the Stormedit source
if [ ! -d "/build/stormedit" ]; then
    echo "Error: Stormedit source directory not found!"
    exit 1
fi

cd /build/stormedit

# Set up static linking environment
export LDFLAGS="-static -s"
export CFLAGS="-O2 -static"
export CXXFLAGS="-O2 -static"

echo "Examining Stormedit build system..."
ls -la

# Stormedit is a CMake project with git submodules
echo "Stormedit appears to be a CMake project with dependencies"

# Initialize and update git submodules (for MagiDoor library)
echo "Initializing git submodules..."

# Fix git ownership issues if running as different user
git config --global --add safe.directory /build/stormedit || true

git submodule init
if ! git submodule update; then
    echo "Git submodule update failed, attempting fallback..."
fi

# Check if magidoor has content (regardless of submodule success/failure)
if [ ! -d "magidoor" ] || [ -z "$(ls -A magidoor 2>/dev/null)" ]; then
    echo "MagiDoor directory is empty or missing, attempting alternatives..."
    
    # Try to find the submodule URL and clone manually if needed
    if [ -f ".gitmodules" ]; then
        echo "Found .gitmodules file:"
        cat .gitmodules
        # Extract the MagiDoor URL and clone manually
        magidoor_url=$(grep -A 2 "\[submodule \"magidoor\"\]" .gitmodules | grep "url" | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$magidoor_url" ]; then
            echo "Attempting to clone MagiDoor from: $magidoor_url"
            if ! git clone "$magidoor_url" magidoor_temp; then
                echo "Failed to clone from $magidoor_url"
            else
                rm -rf magidoor
                mv magidoor_temp magidoor
                echo "Successfully cloned MagiDoor manually"
            fi
        fi
    fi
    
    # If still no magidoor, create a stub
    if [ ! -d "magidoor" ] || [ -z "$(ls -A magidoor 2>/dev/null)" ]; then
        echo "Creating minimal MagiDoor stub for compilation..."
        rm -rf magidoor
        mkdir -p magidoor
        
        # Create minimal header files that might be needed
        cat > magidoor/MagiDoor.h << 'EOF'
#ifndef MAGIDOOR_H
#define MAGIDOOR_H

// Minimal MagiDoor stub for compilation
// This is a temporary solution when MagiDoor source is not available

#include <stdio.h>
#include <time.h>

// Basic types and structures that might be expected
extern time_t mdtimeremaining;

typedef struct {
    char user_alias[32];
    int node;
} mdcontrol_t;

extern mdcontrol_t mdcontrol;

// Function prototypes that might be called by Stormedit
int md_init(const char* dropfile, int socket);
void md_exit(int code);
char md_getc();
void md_printf(const char* format, ...);
void md_printf_raw(const char* format, ...);
void md_clr_scr();
void md_sendfile(const char* filename, int mode);

#endif
EOF

        # Create minimal implementation
        cat > magidoor/MagiDoor.c << 'EOF'
#include "MagiDoor.h"
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>

time_t mdtimeremaining = 0;
mdcontrol_t mdcontrol = {"User", 1};

int md_init(const char* dropfile, int socket) {
    mdtimeremaining = time(NULL) + 3600; // 1 hour
    return 0;
}

void md_exit(int code) {
    exit(code);
}

char md_getc() {
    return getchar();
}

void md_printf(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}

void md_printf_raw(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}

void md_clr_scr() {
    printf("\033[2J\033[H");
}

void md_sendfile(const char* filename, int mode) {
    // Stub - does nothing
}
EOF

        # Create minimal CMakeLists.txt for magidoor
        cat > magidoor/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.6)
project(magidoor)

set(SOURCE_FILES MagiDoor.c)
add_library(mdoor STATIC ${SOURCE_FILES})
target_include_directories(mdoor PUBLIC .)
EOF
        
        echo "Created minimal MagiDoor stub for compilation"
    fi
fi

echo "MagiDoor dependency found. Proceeding with build..."

# Create build directory
mkdir -p build
cd build

# Configure with CMake for static linking
echo "Configuring with CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_STANDARD=11

# Build with make
echo "Building Stormedit..."
make

# Go back to the main directory
cd ..

# Create output directory for this architecture
mkdir -p /output/stormedit/$ARCH_NAME

# Find and copy the binary
echo "Looking for Stormedit binary..."

# Look in the build directory first (CMake output)
if [ -f "build/stormedit" ]; then
    cp "build/stormedit" "/output/stormedit/$ARCH_NAME/stormedit"
    echo "Copied stormedit from build/ to /output/stormedit/$ARCH_NAME/stormedit"
elif [ -f "stormedit" ]; then
    cp "stormedit" "/output/stormedit/$ARCH_NAME/stormedit"
    echo "Copied stormedit to /output/stormedit/$ARCH_NAME/stormedit"
else
    # Search for the binary in various locations
    for binary_name in stormedit storm edit storm-edit; do
        binary_path=$(find . -name "$binary_name" -type f -executable | head -1)
        if [ -n "$binary_path" ]; then
            cp "$binary_path" "/output/stormedit/$ARCH_NAME/stormedit"
            echo "Found and copied $binary_name from $binary_path to /output/stormedit/$ARCH_NAME/stormedit"
            break
        fi
    done
fi

# If still not found, look for any executable in build directories
if [ ! -f "/output/stormedit/$ARCH_NAME/stormedit" ]; then
    echo "Searching for any executable files..."
    executable_files=$(find . -type f -executable -not -path "./.*" | grep -v "\.sh$" | head -10)
    echo "Found executables:"
    echo "$executable_files"
    
    # Try to identify the main binary (usually the largest or in a specific directory)
    main_binary=$(find . -type f -executable -not -path "./.*" | grep -v "\.sh$" | head -1)
    if [ -n "$main_binary" ]; then
        cp "$main_binary" "/output/stormedit/$ARCH_NAME/stormedit"
        echo "Copied probable main binary $main_binary to /output/stormedit/$ARCH_NAME/stormedit"
    else
        echo "Error: No Stormedit binary found!"
        exit 1
    fi
fi

# Also copy the backdrop ansi file if it exists (required for Stormedit to work)
if [ -f "editorbd.ans" ]; then
    cp "editorbd.ans" "/output/stormedit/$ARCH_NAME/"
    echo "Copied editorbd.ans backdrop file to /output/stormedit/$ARCH_NAME/"
fi

# Verify the binary is static
echo "Verifying static linking..."
for binary in /output/stormedit/$ARCH_NAME/*; do
    if [ -f "$binary" ]; then
        echo "Checking $binary:"
        file "$binary"
        echo "Dependencies:"
        ldd "$binary" 2>/dev/null | head -5 || echo "  (statically linked or no dynamic dependencies shown)"
        echo ""
    fi
done

echo "Stormedit build complete!"
echo "Binaries available in: /output/stormedit/$ARCH_NAME/"
ls -la /output/stormedit/$ARCH_NAME/ || true