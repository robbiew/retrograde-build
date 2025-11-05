#!/bin/bash

# Retrograde BBS Binary Builder
# Host system build script for managing Docker builds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    local arch="$1"
    local platform_flag=""
    
    case "$arch" in
        "arm64")
            platform_flag="--platform linux/arm64"
            ;;
        "x86_64")
            platform_flag="--platform linux/amd64"
            ;;
        *)
            print_error "Unknown architecture: $arch"
            return 1
            ;;
    esac
    
    print_status "Building Docker image for $arch..."
    
    cd "$SCRIPT_DIR/$arch"
    
    if docker build $platform_flag -t "retrograde-builder:$arch" .; then
        print_success "Docker image built successfully for $arch"
        return 0
    else
        print_error "Failed to build Docker image for $arch"
        return 1
    fi
}

# Function to run build in container
run_build() {
    local arch="$1"
    local build_args="$2"
    
    print_status "Running build for $arch architecture..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Run the build
    if docker run --rm -v "$OUTPUT_DIR:/output" -v "$SCRIPT_DIR/scripts:/scripts" "retrograde-builder:$arch" /scripts/build-all.sh $build_args; then
        print_success "Build completed successfully for $arch"
        return 0
    else
        print_error "Build failed for $arch"
        return 1
    fi
}

# Function to show help
show_help() {
    cat << EOF
Retrograde BBS Binary Builder

Usage: $0 [OPTIONS] [ARCHITECTURES]

OPTIONS:
    --husky        Build only Husky Project binaries
    --binkd        Build only Binkd
    --stormedit    Build only Stormedit
    --no-build     Skip Docker image building (use existing images)
    --clean        Clean output directory before building
    -h, --help     Show this help message

ARCHITECTURES:
    arm64          Build for ARM64 architecture
    x86_64         Build for x86_64 architecture
    all            Build for both architectures (default)

EXAMPLES:
    $0                           # Build all components for both architectures
    $0 arm64                     # Build all components for ARM64 only
    $0 --husky x86_64            # Build only Husky for x86_64
    $0 --clean --binkd all       # Clean and build only Binkd for both architectures
    $0 --no-build arm64          # Run build without rebuilding Docker image

OUTPUT:
    Binaries will be available in: $OUTPUT_DIR

EOF
}

# Parse command line arguments
BUILD_HUSKY=false
BUILD_BINKD=false
BUILD_STORMEDIT=false
NO_BUILD=false
CLEAN=false
ARCHITECTURES=()
BUILD_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --husky)
            BUILD_HUSKY=true
            BUILD_ARGS="$BUILD_ARGS --husky"
            shift
            ;;
        --binkd)
            BUILD_BINKD=true
            BUILD_ARGS="$BUILD_ARGS --binkd"
            shift
            ;;
        --stormedit)
            BUILD_STORMEDIT=true
            BUILD_ARGS="$BUILD_ARGS --stormedit"
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        arm64|x86_64|all)
            ARCHITECTURES+=("$1")
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set default architecture if none specified
if [ ${#ARCHITECTURES[@]} -eq 0 ]; then
    ARCHITECTURES=("all")
fi

# Expand "all" to both architectures
if [[ " ${ARCHITECTURES[@]} " =~ " all " ]]; then
    ARCHITECTURES=("arm64" "x86_64")
fi

# Validate at least one component is selected (if specific components chosen)
if [ "$BUILD_HUSKY" = false ] && [ "$BUILD_BINKD" = false ] && [ "$BUILD_STORMEDIT" = false ]; then
    BUILD_ARGS=""  # Build all components
fi

print_status "Retrograde BBS Binary Builder"
print_status "=============================="

# Check prerequisites
check_docker

# Clean output directory if requested
if [ "$CLEAN" = true ]; then
    print_status "Cleaning output directory..."
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# Track success/failure
failed_builds=()
successful_builds=()

# Process each architecture
for arch in "${ARCHITECTURES[@]}"; do
    print_status "Processing $arch architecture..."
    
    # Build Docker image unless --no-build is specified
    if [ "$NO_BUILD" = false ]; then
        if ! build_image "$arch"; then
            failed_builds+=("$arch (image build)")
            continue
        fi
    else
        print_status "Skipping Docker image build for $arch (using existing image)"
    fi
    
    # Run the build
    if run_build "$arch" "$BUILD_ARGS"; then
        successful_builds+=("$arch")
    else
        failed_builds+=("$arch (binary build)")
    fi
    
    echo ""
done

# Show final results
print_status "Build Summary"
print_status "============="

if [ ${#successful_builds[@]} -gt 0 ]; then
    print_success "Successful builds:"
    for build in "${successful_builds[@]}"; do
        echo "  ✓ $build"
    done
fi

if [ ${#failed_builds[@]} -gt 0 ]; then
    print_error "Failed builds:"
    for build in "${failed_builds[@]}"; do
        echo "  ✗ $build"
    done
fi

print_status "Output directory: $OUTPUT_DIR"

# Show what was built
if [ -d "$OUTPUT_DIR" ]; then
    print_status "Available binaries:"
    find "$OUTPUT_DIR" -type f -executable -exec ls -la {} \; 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Exit with error code if any builds failed
if [ ${#failed_builds[@]} -gt 0 ]; then
    exit 1
else
    print_success "All builds completed successfully!"
    exit 0
fi