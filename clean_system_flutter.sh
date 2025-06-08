#!/bin/bash

# Finds Flutter projects on macOS and cleans build/cache directories
# Supports --dry-run and excludes Flutter SDK and FVM directories

set -e

DRY_RUN=false
TOTAL_SIZE=0
DELETED_PATHS=()
EXCLUDED_PATHS=("$HOME/flutter" "$HOME/.fvm")

# Convert bytes to human-readable format
human_readable() {
    num=$1
    echo $(/usr/bin/osascript -e "set theNumber to $num
        if theNumber ≥ 1073741824 then
            return (round (theNumber / 1073741824 * 10) / 10) & \" GB\"
        else if theNumber ≥ 1048576 then
            return (round (theNumber / 1048576 * 10) / 10) & \" MB\"
        else if theNumber ≥ 1024 then
            return (round (theNumber / 1024 * 10) / 10) & \" KB\"
        else
            return theNumber & \" B\"
        end if")
}

# Check if path should be excluded
is_excluded() {
    local target="$1"
    for excluded in "${EXCLUDED_PATHS[@]}"; do
        if [[ "$target" == "$excluded"* ]]; then
            return 0
        fi
    done
    return 1
}

# Measure size and optionally delete
process_path() {
    local path=$1
    if [ -d "$path" ]; then
        if is_excluded "$path"; then
            return
        fi
        local size=$(du -sk "$path" | cut -f1)
        size=$((size * 1024))
        TOTAL_SIZE=$((TOTAL_SIZE + size))
        DELETED_PATHS+=("$path")
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$path"
        fi
    fi
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            echo "Usage: $0 [--dry-run]"
            exit 1
            ;;
    esac
done

echo "🔍 Searching for Flutter projects on your system..."

# Locate pubspec.yaml files that contain 'flutter:'
PROJECTS=$(mdfind "kMDItemFSName = 'pubspec.yaml' && kMDItemTextContent = 'flutter:'")

for project_file in $PROJECTS; do
    PROJECT_DIR=$(dirname "$project_file")
    
    if is_excluded "$PROJECT_DIR"; then
        echo "⚠️  Skipped (excluded): $PROJECT_DIR"
        continue
    fi

    echo "🧹 Found Flutter project: $PROJECT_DIR"

    process_path "$PROJECT_DIR/.dart_tool"
    process_path "$PROJECT_DIR/build"
    process_path "$PROJECT_DIR/.flutter-plugins"
    process_path "$PROJECT_DIR/.packages"
    process_path "$PROJECT_DIR/ios/Pods"
    process_path "$PROJECT_DIR/ios/.symlinks"
    process_path "$PROJECT_DIR/ios/Flutter/Flutter.framework"
    process_path "$PROJECT_DIR/.ios/Flutter/Flutter.framework"
    process_path "$PROJECT_DIR/macos/Flutter/ephemeral"
    process_path "$PROJECT_DIR/.fvm/flutter_sdk"
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "🧪 Dry run mode: the following paths would be deleted:"
    for path in "${DELETED_PATHS[@]}"; do
        echo "  $path"
    done
    echo "💾 Estimated space savings: $(human_readable $TOTAL_SIZE)"
else
    echo "✅ Cleanup complete."
    echo "🗑️ Freed up space: $(human_readable $TOTAL_SIZE)"
fi
