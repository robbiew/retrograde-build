#!/bin/bash

# Create release archives for external binaries
# Packages the built binaries into tar.gz archives ready for GitHub releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/output"
ARCHIVES_DIR="$PROJECT_ROOT/archives"

# Version from environment or default
VERSION="${VERSION:-$(date +%Y%m%d)}"

echo -e "${BLUE}============================================${NC}"
echo -e "${CYAN}  Creating External Binary Release Archives${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Version:${NC} $VERSION"
echo -e "${YELLOW}Output Directory:${NC} $OUTPUT_DIR"
echo -e "${YELLOW}Archives Directory:${NC} $ARCHIVES_DIR"
echo ""

# Check if output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}✗${NC} Output directory not found: $OUTPUT_DIR"
    echo -e "Run ./build.sh first to generate binaries"
    exit 1
fi

# Create archives directory
mkdir -p "$ARCHIVES_DIR"

# Binary version mappings
declare -A BINARY_VERSIONS=(
    ["hpt"]="1.9.0"
    ["binkd"]="1.1.0"
    ["stormedit"]="4.0"
)

# Function to create archive for a specific binary and architecture
create_binary_archive() {
    local binary_name="$1"
    local arch="$2"
    local version="${BINARY_VERSIONS[$binary_name]}"
    
    echo -e "${CYAN}Creating archive for $binary_name ($arch)...${NC}"
    
    # Find the binary in the output directory
    local binary_path=""
    if [ -f "$OUTPUT_DIR/$arch/husky/$binary_name" ]; then
        binary_path="$OUTPUT_DIR/$arch/husky/$binary_name"
    elif [ -f "$OUTPUT_DIR/$arch/binkd/$binary_name" ]; then
        binary_path="$OUTPUT_DIR/$arch/binkd/$binary_name"
    elif [ -f "$OUTPUT_DIR/$arch/stormedit/$binary_name" ]; then
        binary_path="$OUTPUT_DIR/$arch/stormedit/$binary_name"
    elif [ -f "$OUTPUT_DIR/$arch/$binary_name/$binary_name" ]; then
        binary_path="$OUTPUT_DIR/$arch/$binary_name/$binary_name"
    else
        echo -e "${YELLOW}⚠${NC} Binary not found: $binary_name for $arch"
        return 1
    fi
    
    if [ ! -f "$binary_path" ]; then
        echo -e "${YELLOW}⚠${NC} Binary file not found: $binary_path"
        return 1
    fi
    
    # Create temp directory for this archive
    local temp_dir="$ARCHIVES_DIR/tmp-$binary_name-$arch"
    mkdir -p "$temp_dir"
    
    # Copy binary to temp directory
    cp "$binary_path" "$temp_dir/$binary_name"
    chmod +x "$temp_dir/$binary_name"
    
    # Create archive
    local archive_name="$binary_name-$version-linux-$arch.tar.gz"
    local archive_path="$ARCHIVES_DIR/$archive_name"
    
    tar -czf "$archive_path" -C "$temp_dir" "$binary_name"
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    if [ -f "$archive_path" ]; then
        local size=$(du -h "$archive_path" | cut -f1)
        echo -e "${GREEN}✓${NC} Created: $archive_name ($size)"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create: $archive_name"
        return 1
    fi
}

# Function to process all binaries for an architecture
process_architecture() {
    local arch="$1"
    local arch_dir="$OUTPUT_DIR/$arch"
    
    if [ ! -d "$arch_dir" ]; then
        echo -e "${YELLOW}⚠${NC} Architecture directory not found: $arch"
        return 1
    fi
    
    echo -e "${YELLOW}Processing $arch architecture...${NC}"
    
    local success_count=0
    local total_count=0
    
    # Process each binary
    for binary in hpt binkd stormedit; do
        total_count=$((total_count + 1))
        if create_binary_archive "$binary" "$arch"; then
            success_count=$((success_count + 1))
        fi
    done
    
    echo -e "${CYAN}$arch Summary: $success_count/$total_count binaries archived${NC}"
    echo ""
    
    return 0
}

# Main processing
echo -e "${CYAN}Scanning output directory...${NC}"

# Find available architectures
ARCHITECTURES=()
for arch_dir in "$OUTPUT_DIR"/*; do
    if [ -d "$arch_dir" ]; then
        arch_name=$(basename "$arch_dir")
        ARCHITECTURES+=("$arch_name")
    fi
done

if [ ${#ARCHITECTURES[@]} -eq 0 ]; then
    echo -e "${RED}✗${NC} No architecture directories found in $OUTPUT_DIR"
    echo -e "Available directories:"
    ls -la "$OUTPUT_DIR" || echo "  (directory is empty)"
    exit 1
fi

echo -e "${GREEN}Found architectures:${NC} ${ARCHITECTURES[*]}"
echo ""

# Process each architecture
total_success=0
total_archives=0

for arch in "${ARCHITECTURES[@]}"; do
    if process_architecture "$arch"; then
        # Count successful archives for this arch
        arch_archives=$(find "$ARCHIVES_DIR" -name "*-linux-$arch.tar.gz" 2>/dev/null | wc -l)
        total_success=$((total_success + arch_archives))
    fi
done

# Count total archives created
total_archives=$(find "$ARCHIVES_DIR" -name "*.tar.gz" 2>/dev/null | wc -l)

echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  Archive Creation Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ $total_archives -gt 0 ]; then
    echo -e "${CYAN}Created archives:${NC}"
    for archive in "$ARCHIVES_DIR"/*.tar.gz; do
        if [ -f "$archive" ]; then
            local basename_archive=$(basename "$archive")
            local size=$(du -h "$archive" | cut -f1)
            echo -e "  • ${basename_archive} (${size})"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Successfully created $total_archives archives${NC}"
    echo -e "${CYAN}Archives location:${NC} $ARCHIVES_DIR"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Upload to GitHub releases:"
    echo -e "   ./scripts/upload-to-retrograde-release.sh"
    echo -e "2. Or upload manually via GitHub web interface"
    
else
    echo -e "${RED}✗ No archives were created${NC}"
    echo -e "Check that binaries exist in: $OUTPUT_DIR"
    exit 1
fi

echo -e "${BLUE}============================================${NC}"