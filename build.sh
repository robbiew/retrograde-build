#!/bin/bash

# Retrograde BBS Builder Script
# Builds static binaries for external programs bundled with Retrograde BBS releases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [--component] [architecture]"
    echo ""
    echo "Components:"
    echo "  --all         Build all components (default)"
    echo "  --husky       Build Husky Project only"
    echo "  --binkd       Build Binkd only" 
    echo "  --stormedit   Build Stormedit only"
    echo ""
    echo "Architectures:"
    echo "  x86_64        Build for x86_64/amd64"
    echo "  arm64         Build for ARM64/aarch64"
    echo "  both          Build for both architectures"
    echo ""
    echo "Examples:"
    echo "  $0 --all x86_64"
    echo "  $0 --binkd arm64"
    echo "  $0 --all both"
    exit 1
}

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

build_component() {
    local component=$1
    local arch=$2
    local script_name=""
    
    case $component in
        "husky")
            script_name="build-husky.sh"
            ;;
        "binkd")
            script_name="build-binkd.sh"
            ;;
        "stormedit")
            script_name="build-stormedit.sh"
            ;;
        "all")
            script_name="build-all.sh"
            ;;
        *)
            error "Unknown component: $component"
            return 1
            ;;
    esac
    
    log "Building $component for $arch architecture..."
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Run the build in container with output volume mounted
    if docker run --rm \
        -v "$SCRIPT_DIR/retrograde-builders/scripts:/scripts" \
        -v "$OUTPUT_DIR:/output" \
        "retrograde-builder:$arch" \
        "/scripts/$script_name"; then
        success "$component build completed for $arch"
        return 0
    else
        error "$component build failed for $arch"
        return 1
    fi
}

build_architecture() {
    local component=$1
    local arch=$2
    
    log "Checking if container exists for $arch..."
    if ! docker image inspect "retrograde-builder:$arch" >/dev/null 2>&1; then
        warn "Container retrograde-builder:$arch not found. Building..."
        if ! docker build -t "retrograde-builder:$arch" "retrograde-builders/$arch/"; then
            error "Failed to build container for $arch"
            return 1
        fi
        success "Container built for $arch"
    fi
    
    build_component "$component" "$arch"
}

show_results() {
    log "Build Results:"
    echo ""
    
    if [ -d "$OUTPUT_DIR" ]; then
        echo "Output directory: $OUTPUT_DIR"
        echo ""
        
        for arch_dir in "$OUTPUT_DIR"/*; do
            if [ -d "$arch_dir" ]; then
                arch_name=$(basename "$arch_dir")
                echo "=== $arch_name Architecture ==="
                
                for component_dir in "$arch_dir"/*; do
                    if [ -d "$component_dir" ]; then
                        component_name=$(basename "$component_dir")
                        echo "  $component_name:"
                        ls -lh "$component_dir" | grep -v "^total" | while read -r line; do
                            echo "    $line"
                        done
                        echo ""
                    fi
                done
            fi
        done
    else
        warn "No output directory found"
    fi
}

# Parse arguments
COMPONENT="all"
ARCHITECTURE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            COMPONENT="all"
            shift
            ;;
        --husky)
            COMPONENT="husky"
            shift
            ;;
        --binkd)
            COMPONENT="binkd"
            shift
            ;;
        --stormedit)
            COMPONENT="stormedit"
            shift
            ;;
        x86_64|arm64|both)
            ARCHITECTURE="$1"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate arguments
if [ -z "$ARCHITECTURE" ]; then
    error "Architecture not specified"
    usage
fi

# Main build process
echo "======================================================="
echo "=== Retrograde BBS Static Binary Builder ==="
echo "======================================================="
echo ""

case $ARCHITECTURE in
    "both")
        log "Building for both architectures..."
        build_architecture "$COMPONENT" "x86_64"
        build_architecture "$COMPONENT" "arm64"
        ;;
    "x86_64"|"arm64")
        build_architecture "$COMPONENT" "$ARCHITECTURE"
        ;;
    *)
        error "Invalid architecture: $ARCHITECTURE"
        usage
        ;;
esac

echo ""
echo "======================================================="
echo "=== Build Complete ==="
echo "======================================================="
echo ""

show_results