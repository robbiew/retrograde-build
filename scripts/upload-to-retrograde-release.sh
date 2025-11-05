#!/bin/bash

# Upload External Binaries to Retrograde GitHub Release
# This script uploads all built external binaries to the specified Retrograde release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
RETROGRADE_REPO="robbiew/retrograde"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/output"
ARCHIVES_DIR="$PROJECT_ROOT/archives"

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTIONS] RELEASE_TAG"
    echo ""
    echo "Upload external binaries from DockerBuilds output to Retrograde GitHub release."
    echo ""
    echo "Arguments:"
    echo "  RELEASE_TAG       Target release tag (e.g., v1.0.1)"
    echo ""
    echo "Options:"
    echo "  -f, --force       Force overwrite existing assets"
    echo "  -n, --dry-run     Show what would be uploaded without uploading"
    echo "  -v, --verbose     Verbose output"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 v1.0.1                    # Upload to v1.0.1 release"
    echo "  $0 --force v1.0.1            # Force overwrite existing assets"
    echo "  $0 --dry-run v1.0.1          # Preview what would be uploaded"
    echo ""
    echo "Prerequisites:"
    echo "  - GitHub CLI (gh) must be installed and authenticated"
    echo "  - RETROGRADE_RELEASE_TOKEN environment variable or gh auth"
    echo "  - External binaries must be built first (./build.sh --all both)"
}

# Default options
FORCE_OVERWRITE=false
DRY_RUN=false
VERBOSE=false
RELEASE_TAG=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}✗${NC} Unknown option: $1" >&2
            print_usage >&2
            exit 1
            ;;
        *)
            if [ -z "$RELEASE_TAG" ]; then
                RELEASE_TAG="$1"
            else
                echo -e "${RED}✗${NC} Multiple release tags specified" >&2
                print_usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$RELEASE_TAG" ]; then
    echo -e "${RED}✗${NC} Release tag is required" >&2
    print_usage >&2
    exit 1
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${CYAN}  Upload External Binaries to Retrograde${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Target Repository:${NC} $RETROGRADE_REPO"
echo -e "${YELLOW}Release Tag:${NC} $RELEASE_TAG"
echo -e "${YELLOW}Output Directory:${NC} $OUTPUT_DIR"
echo -e "${YELLOW}Archives Directory:${NC} $ARCHIVES_DIR"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Mode:${NC} DRY RUN (no actual uploads)"
fi
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗${NC} GitHub CLI (gh) not found"
    echo -e "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗${NC} Not authenticated with GitHub"
    echo -e "Please run: ${CYAN}gh auth login${NC}"
    echo -e "Or set RETROGRADE_RELEASE_TOKEN environment variable"
    exit 1
fi

# Check if archives already exist or if we need to build from output
if [ -d "$ARCHIVES_DIR" ] && [ "$(ls -A "$ARCHIVES_DIR"/*.tar.gz 2>/dev/null | wc -l)" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found pre-built archives in $ARCHIVES_DIR"
    USE_PREBUILT_ARCHIVES=true
elif [ -d "$OUTPUT_DIR" ]; then
    echo -e "${CYAN}No pre-built archives found, will create from output directory${NC}"
    USE_PREBUILT_ARCHIVES=false
else
    echo -e "${RED}✗${NC} Neither archives directory nor output directory found"
    echo -e "Please run: ${CYAN}./build.sh --all both${NC} first"
    echo -e "Or: ${CYAN}./scripts/create-release-archives.sh${NC} to create archives"
    exit 1
fi

# Check if release exists
echo -e "${CYAN}Checking if release exists...${NC}"
if ! gh release view "$RELEASE_TAG" --repo "$RETROGRADE_REPO" &>/dev/null; then
    echo -e "${RED}✗${NC} Release $RELEASE_TAG does not exist in $RETROGRADE_REPO"
    echo -e "Please create the release first at:"
    echo -e "  ${CYAN}https://github.com/$RETROGRADE_REPO/releases/new${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Release $RELEASE_TAG found"

# Function to create architecture-specific archives
create_archives() {
    local temp_dir="$PROJECT_ROOT/temp_archives"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    echo -e "${CYAN}Creating release archives...${NC}"
    
    for arch in x86_64 arm64; do
        echo -e "${BLUE}Processing $arch architecture...${NC}"
        
        # Create staging directory
        local staging_dir="$temp_dir/staging/$arch"
        mkdir -p "$staging_dir"
        
        # Track if we found any binaries for this architecture
        local found_binaries=false
        
        # Look for binaries in architecture-specific output
        if [ -d "$OUTPUT_DIR/$arch" ]; then
            for component_dir in "$OUTPUT_DIR/$arch"/*; do
                if [ -d "$component_dir" ]; then
                    local component=$(basename "$component_dir")
                    
                    echo -e "  ${YELLOW}Processing $component...${NC}"
                    
                    # Copy binaries with standardized names
                    case "$component" in
                        "husky"|"hpt")
                            if [ -f "$component_dir/hpt" ]; then
                                cp "$component_dir/hpt" "$staging_dir/hpt-static-$arch"
                                chmod +x "$staging_dir/hpt-static-$arch"
                                echo -e "  ${GREEN}✓${NC} Added hpt-static-$arch"
                                found_binaries=true
                            fi
                            if [ -f "$component_dir/hptutil" ]; then
                                cp "$component_dir/hptutil" "$staging_dir/hptutil-static-$arch"
                                chmod +x "$staging_dir/hptutil-static-$arch"
                                echo -e "  ${GREEN}✓${NC} Added hptutil-static-$arch"
                                found_binaries=true
                            fi
                            ;;
                        "binkd")
                            if [ -f "$component_dir/binkd" ]; then
                                cp "$component_dir/binkd" "$staging_dir/binkd-static-$arch"
                                chmod +x "$staging_dir/binkd-static-$arch"
                                echo -e "  ${GREEN}✓${NC} Added binkd-static-$arch"
                                found_binaries=true
                            fi
                            ;;
                        "stormedit")
                            if [ -f "$component_dir/stormedit" ]; then
                                cp "$component_dir/stormedit" "$staging_dir/stormedit-static-$arch"
                                chmod +x "$staging_dir/stormedit-static-$arch"
                                echo -e "  ${GREEN}✓${NC} Added stormedit-static-$arch"
                                found_binaries=true
                            fi
                            ;;
                    esac
                fi
            done
        fi
        
        # Create archive if we have binaries
        if [ "$found_binaries" = true ]; then
            local archive_name="retrograde-external-binaries-${RELEASE_TAG}-linux-${arch}.tar.gz"
            local archive_path="$temp_dir/$archive_name"
            
            echo -e "  ${CYAN}Creating archive: $archive_name${NC}"
            tar -czf "$archive_path" -C "$staging_dir" .
            
            local size=$(ls -lh "$archive_path" | awk '{print $5}')
            echo -e "  ${GREEN}✓${NC} Created $archive_name (${size})"
            
            # Add to archives list
            echo "$archive_path" >> "$temp_dir/archives_list.txt"
        else
            echo -e "  ${YELLOW}⚠${NC} No binaries found for $arch architecture"
        fi
        
        echo ""
    done
    
    echo "$temp_dir"
}

# Create or use existing archives
if [ "$USE_PREBUILT_ARCHIVES" = true ]; then
    echo -e "${CYAN}Using pre-built archives from $ARCHIVES_DIR${NC}"
    TEMP_ARCHIVES_DIR="$ARCHIVES_DIR"
    
    # Create archives list
    ARCHIVES=()
    for archive in "$ARCHIVES_DIR"/*.tar.gz; do
        if [ -f "$archive" ]; then
            ARCHIVES+=("$archive")
        fi
    done
    
    if [ ${#ARCHIVES[@]} -eq 0 ]; then
        echo -e "${RED}✗${NC} No .tar.gz archives found in $ARCHIVES_DIR"
        exit 1
    fi
else
    # Create archives from output directory
    TEMP_ARCHIVES_DIR=$(create_archives)
    
    # Check if we have any archives to upload
    if [ ! -f "$TEMP_ARCHIVES_DIR/archives_list.txt" ]; then
        echo -e "${RED}✗${NC} No archives created. No binaries found in $OUTPUT_DIR"
        echo -e "Please run: ${CYAN}./build.sh --all both${NC} first"
        exit 1
    fi
    
    # List archives to upload
    ARCHIVES=($(cat "$TEMP_ARCHIVES_DIR/archives_list.txt"))
fi

# List archives to upload
echo -e "${CYAN}Archives to upload:${NC}"

for archive in "${ARCHIVES[@]}"; do
    basename_archive=$(basename "$archive")
    size=$(ls -lh "$archive" | awk '{print $5}')
    echo -e "  • ${basename_archive} (${size})"
done

echo ""

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN: Would upload these archives to $RELEASE_TAG${NC}"
    exit 0
fi

# Confirm upload
if [ "$FORCE_OVERWRITE" != true ]; then
    read -r -p "Upload these archives to $RELEASE_TAG? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Upload cancelled.${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${CYAN}Uploading archives...${NC}"

# Upload each archive
SUCCESS_COUNT=0
TOTAL_COUNT=${#ARCHIVES[@]}

for archive in "${ARCHIVES[@]}"; do
    basename_archive=$(basename "$archive")
    echo -e "${BLUE}Uploading:${NC} $basename_archive"
    
    # Check if asset already exists
    if gh release view "$RELEASE_TAG" --repo "$RETROGRADE_REPO" --json assets --jq ".assets[].name" | grep -q "^${basename_archive}$"; then
        if [ "$FORCE_OVERWRITE" = true ]; then
            echo -e "${YELLOW}  Deleting existing asset...${NC}"
            gh release delete-asset "$RELEASE_TAG" "$basename_archive" --repo "$RETROGRADE_REPO" --yes
        else
            echo -e "${RED}✗${NC} Asset already exists: $basename_archive"
            echo -e "   Use --force to overwrite"
            continue
        fi
    fi
    
    # Upload the archive
    if gh release upload "$RELEASE_TAG" "$archive" --repo "$RETROGRADE_REPO" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Uploaded: $basename_archive"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${RED}✗${NC} Failed: $basename_archive"
    fi
done

# Clean up temporary directory (only if we created it)
if [ "$USE_PREBUILT_ARCHIVES" != true ]; then
    rm -rf "$TEMP_ARCHIVES_DIR"
fi

echo ""
echo -e "${BLUE}============================================${NC}"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}✓ All archives uploaded successfully!${NC}"
    echo ""
    echo -e "${CYAN}Verify upload:${NC}"
    echo -e "  gh release view $RELEASE_TAG --repo $RETROGRADE_REPO --json assets --jq '.assets[].name'"
    echo ""
    echo -e "${CYAN}Release URL:${NC}"
    echo -e "  https://github.com/$RETROGRADE_REPO/releases/tag/$RELEASE_TAG"
else
    echo -e "${RED}✗ Some uploads failed ($SUCCESS_COUNT/$TOTAL_COUNT)${NC}"
    exit 1
fi

echo -e "${BLUE}============================================${NC}"