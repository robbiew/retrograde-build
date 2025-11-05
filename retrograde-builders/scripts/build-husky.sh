#!/bin/bash

# Husky Project Build Script
# This script uses the official Husky installation method to build static binaries

set -e

echo "=== Building Husky Project Binaries ==="
echo "Using official installation script from huskyproject/huskybse"

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

# Change to build directory
cd /build

# Download and run the Husky installation script
echo "Downloading Husky installation script..."
wget https://raw.githubusercontent.com/huskyproject/huskybse/master/script/init_build
chmod +x init_build

# The init_build script refuses to run as root, so we need to create a non-root user
echo "Creating non-root user for Husky build..."
if ! id "huskyuser" &>/dev/null; then
    useradd -m -s /bin/bash huskyuser
fi

# Make the non-root user owner of the build directory
chown -R huskyuser:huskyuser /build

# Run the initialization script as non-root user
echo "Initializing Husky build environment as non-root user..."
su - huskyuser -c "cd /build && ./init_build -d /build/husky"

# Change back to the husky directory as root for the rest of the build
cd /build/husky

# Modify huskymak.cfg for static builds
echo "Configuring Husky for static builds..."
cp huskymak.cfg huskymak.cfg.bak

# Set static linking options in huskymak.cfg
sed -i 's/#DYNLIBS=1/DYNLIBS=0/' huskymak.cfg || echo "DYNLIBS=0" >> huskymak.cfg
sed -i 's/#DEBUG=1/DEBUG=0/' huskymak.cfg || echo "DEBUG=0" >> huskymak.cfg

# Disable Perl for static builds (Perl static linking is problematic)
sed -i 's/^PERL=1/PERL=0/' huskymak.cfg || true
sed -i 's/#PERL=0/PERL=0/' huskymak.cfg || echo "PERL=0" >> huskymak.cfg

# Enable static linking flags
export LDFLAGS="-static -s"
export CFLAGS="-O2 -static"
export CXXFLAGS="-O2 -static"

# Ensure we're building the main programs we need
# Check if PROGRAMS line exists and modify it, or add it
if grep -q "^PROGRAMS=" huskymak.cfg; then
    sed -i 's/^PROGRAMS=.*/PROGRAMS=hpt htick fidoconf/' huskymak.cfg
else
    echo "PROGRAMS=hpt htick fidoconf" >> huskymak.cfg
fi

# Make sure we have all the required libraries enabled
echo "Ensuring required libraries are enabled..."
if ! grep -q "^USE_HPTZIP=" huskymak.cfg; then
    echo "USE_HPTZIP=1" >> huskymak.cfg
fi

echo "Updated huskymak.cfg configuration:"
echo "=================================="
grep -E "^(DYNLIBS|DEBUG|PROGRAMS|USE_HPTZIP)" huskymak.cfg || true
echo "=================================="

# Build Husky
echo "Building Husky binaries..."
su - huskyuser -c "cd /build/husky && ./build.sh"

# Check what was built
echo "Build completed. Looking for binaries..."
find . -name "hpt" -o -name "htick" -o -name "fidoconf" -type f 2>/dev/null | head -20

# Create output directory for this architecture
mkdir -p /output/husky/$ARCH_NAME

# Copy the built binaries to output directory
echo "Copying binaries to output directory..."

# Find all executable binaries in the Husky build
echo "Searching for all Husky binaries..."
find . -type f -executable -name "*" | grep -E "(Build/|/bin/)" | while read binary_path; do
    if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        binary_name=$(basename "$binary_path")
        # Skip libraries, object files, and format converters we don't need
        if [[ ! "$binary_name" == lib* ]] && [[ ! "$binary_name" == *.a ]] && [[ ! "$binary_name" == *.o ]] && [[ ! "$binary_name" == *.so* ]] && \
           [[ ! "$binary_name" == fconf2* ]] && [[ ! "$binary_name" == fecfg2* ]]; then
            echo "Found binary: $binary_name at $binary_path"
            cp "$binary_path" "/output/husky/$ARCH_NAME/"
            echo "Copied $binary_name to /output/husky/$ARCH_NAME/"
        fi
    fi
done

# Also specifically look for main programs by name
echo "Looking for specific Husky programs..."
for program in hpt htick hptlink hpttree pktinfo txt2pkt tpkt gnmsgid tparser linked; do
    program_path=$(find . -name "$program" -type f -executable | head -1)
    if [ -n "$program_path" ] && [ -f "$program_path" ]; then
        echo "Found $program at: $program_path"
        # Only copy if not already copied
        if [ ! -f "/output/husky/$ARCH_NAME/$program" ]; then
            cp "$program_path" "/output/husky/$ARCH_NAME/"
            echo "Copied $program to /output/husky/$ARCH_NAME/"
        else
            echo "$program already copied"
        fi
    fi
done

# Verify the binaries are static
echo "Verifying static linking..."
for binary in /output/husky/$ARCH_NAME/*; do
    if [ -f "$binary" ]; then
        echo "Checking $binary:"
        file "$binary"
        echo "Dependencies:"
        ldd "$binary" 2>/dev/null | head -5 || echo "  (statically linked or no dynamic dependencies shown)"
        echo ""
    fi
done

echo "Husky build complete!"
echo "Binaries available in: /output/husky/$ARCH_NAME/"
ls -la /output/husky/$ARCH_NAME/ || true