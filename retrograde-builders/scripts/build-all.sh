#!/bin/bash

# Master Build Script for Retrograde BBS Static Binaries
# This script builds all components for the current architecture

set -e

echo "======================================================="
echo "=== Retrograde BBS Static Binary Builder ==="
echo "======================================================="

# Determine architecture
if [ -n "$FORCE_ARCH" ]; then
    ARCH_NAME="$FORCE_ARCH"
    echo "Using forced architecture: $ARCH_NAME"
else
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        ARCH_NAME="arm64"
    elif [ "$ARCH" = "x86_64" ]; then
        ARCH_NAME="x86_64"
    else
        ARCH_NAME="$ARCH"
    fi
    echo "Detected architecture: $ARCH_NAME"
fi
echo "Build directory: /build"
echo "Output directory: /output"
echo ""

# Create output directory structure
mkdir -p /output/{husky,binkd,stormedit,sexyz}/$ARCH_NAME

# Function to run a build script with error handling
run_build() {
    local script_name="$1"
    local component_name="$2"
    
    echo "======================================================="
    echo "=== Building $component_name ==="
    echo "======================================================="
    
    if [ -f "/scripts/$script_name" ]; then
        if /scripts/$script_name; then
            echo "✓ $component_name build completed successfully"
        else
            echo "✗ $component_name build failed!"
            return 1
        fi
    else
        echo "✗ Build script /scripts/$script_name not found!"
        return 1
    fi
    
    echo ""
}

# Parse command line arguments
BUILD_ALL=true
BUILD_HUSKY=false
BUILD_BINKD=false
BUILD_STORMEDIT=false
BUILD_SEXYZ=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --husky)
            BUILD_ALL=false
            BUILD_HUSKY=true
            shift
            ;;
        --binkd)
            BUILD_ALL=false
            BUILD_BINKD=true
            shift
            ;;
        --stormedit)
            BUILD_ALL=false
            BUILD_STORMEDIT=true
            shift
            ;;
        --sexyz)
            BUILD_ALL=false
            BUILD_SEXYZ=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--husky] [--binkd] [--stormedit] [--sexyz]"
            echo ""
            echo "Options:"
            echo "  --husky     Build only Husky Project binaries"
            echo "  --binkd     Build only Binkd"
            echo "  --stormedit Build only Stormedit"
            echo "  --sexyz     Build only SEXYZ (X/Y/Z-modem protocols)"
            echo "  --help, -h  Show this help message"
            echo ""
            echo "If no options are specified, all components will be built."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build components based on arguments
if [ "$BUILD_ALL" = true ] || [ "$BUILD_HUSKY" = true ]; then
    if ! run_build "build-husky.sh" "Husky Project"; then
        echo "Husky build failed, but continuing with other builds..."
    fi
fi

if [ "$BUILD_ALL" = true ] || [ "$BUILD_BINKD" = true ]; then
    if ! run_build "build-binkd.sh" "Binkd"; then
        echo "Binkd build failed, but continuing with other builds..."
    fi
fi

if [ "$BUILD_ALL" = true ] || [ "$BUILD_STORMEDIT" = true ]; then
    if ! run_build "build-stormedit.sh" "Stormedit"; then
        echo "Stormedit build failed, but continuing with other builds..."
    fi
fi

if [ "$BUILD_ALL" = true ] || [ "$BUILD_SEXYZ" = true ]; then
    if ! run_build "build-sexyz.sh" "SEXYZ (X/Y/Z-modem protocols)"; then
        echo "SEXYZ build failed, but continuing with other builds..."
    fi
fi

echo "======================================================="
echo "=== Build Summary ==="
echo "======================================================="

# Show what was built
echo "Built binaries for $ARCH_NAME:"
echo ""

for component in husky binkd stormedit sexyz; do
    component_dir="/output/$component/$ARCH_NAME"
    if [ -d "$component_dir" ] && [ "$(ls -A $component_dir 2>/dev/null)" ]; then
        echo "$component:"
        ls -la "$component_dir"
        echo ""
    else
        echo "$component: No binaries found"
        echo ""
    fi
done

# Create a summary file
cat > /output/build-summary-$ARCH_NAME.txt << EOF
Retrograde BBS Static Binary Build Summary
==========================================

Architecture: $ARCH_NAME
Build Date: $(date)
Build Host: $(hostname)

Components Built:
EOF

for component in husky binkd stormedit sexyz; do
    component_dir="/output/$component/$ARCH_NAME"
    echo "" >> /output/build-summary-$ARCH_NAME.txt
    echo "$component:" >> /output/build-summary-$ARCH_NAME.txt
    if [ -d "$component_dir" ] && [ "$(ls -A $component_dir 2>/dev/null)" ]; then
        ls -la "$component_dir" >> /output/build-summary-$ARCH_NAME.txt
    else
        echo "  No binaries found" >> /output/build-summary-$ARCH_NAME.txt
    fi
done

echo "Build summary saved to: /output/build-summary-$ARCH_NAME.txt"
echo ""
echo "======================================================="
echo "=== All Builds Complete ==="
echo "======================================================="
echo ""
echo "To extract binaries from the container, use:"
echo "  docker cp <container_name>:/output ./retrograde-binaries"
echo ""
echo "Or mount a volume to /output when running the container:"
echo "  docker run -v \$(pwd)/output:/output <image_name> /scripts/build-all.sh"