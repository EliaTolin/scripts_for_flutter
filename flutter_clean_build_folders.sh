#!/bin/bash
# ============================================================
# Flutter Build Cleaner
# Finds all Flutter build folders and deletes them
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SEARCH_ROOT="${1:-/}"

echo -e "${CYAN}${BOLD}"
echo "============================================================"
echo "  Flutter Build Cleaner"
echo "============================================================"
echo -e "${NC}"
echo -e "Searching in: ${BOLD}$SEARCH_ROOT${NC}"
echo -e "Looking for ${BOLD}build/${NC} folders inside Flutter projects..."
echo ""

BUILD_DIRS=()
SIZES=()
TOTAL_BYTES=0

while IFS= read -r pubspec; do
    project_dir=$(dirname "$pubspec")
    build_dir="$project_dir/build"

    if [ -d "$build_dir" ]; then
        size_bytes=$(du -sk "$build_dir" 2>/dev/null | awk '{print $1}')
        size_bytes=$((size_bytes * 1024))

        BUILD_DIRS+=("$build_dir")
        SIZES+=("$size_bytes")
        TOTAL_BYTES=$((TOTAL_BYTES + size_bytes))

        size_mb=$((size_bytes / 1048576))
        echo -e "  ${YELLOW}${size_mb} MB${NC}  $build_dir"
    fi
done < <(find "$SEARCH_ROOT" -name "pubspec.yaml" \
    -not -path "*/.pub-cache/*" \
    -not -path "*/.dart_tool/*" \
    -not -path "*/build/*" \
    -not -path "*/.symlinks/*" \
    -not -path "*/.Trash/*" \
    2>/dev/null)

echo ""
echo -e "${BOLD}============================================================${NC}"

if [ ${#BUILD_DIRS[@]} -eq 0 ]; then
    echo -e "${GREEN}No build folders found. All clean!${NC}"
    exit 0
fi

TOTAL_MB=$((TOTAL_BYTES / 1048576))
TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_BYTES / 1073741824}")

echo -e "  Found: ${BOLD}${#BUILD_DIRS[@]}${NC} build folders"
echo -e "  Total: ${BOLD}${RED}${TOTAL_MB} MB (${TOTAL_GB} GB)${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""

echo -e "${YELLOW}Do you want to delete all ${#BUILD_DIRS[@]} build folders? [y/N]${NC} "
read -r answer

if [[ "$answer" =~ ^[yY]$ ]]; then
    echo ""
    for i in "${!BUILD_DIRS[@]}"; do
        dir="${BUILD_DIRS[$i]}"
        size_mb=$((SIZES[$i] / 1048576))
        rm -rf "$dir"
        echo -e "  ${GREEN}✓${NC} Deleted ($size_mb MB)  $dir"
    done
    echo ""
    echo -e "${GREEN}${BOLD}✅ Freed ${TOTAL_MB} MB (${TOTAL_GB} GB)${NC}"
else
    echo -e "${YELLOW}Operation cancelled.${NC}"
fi
