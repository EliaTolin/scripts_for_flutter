#!/bin/bash

# Configurable variables
FASTLANE_ANDROID_COMMAND="fastlane deploy"
FASTLANE_IOS_COMMAND="fastlane release"
PROJECT_PATH=$(pwd)
ERROR_LOG_FILE="deploy_flutter.log"
VERBOSE=false
SKIP_ANALYZE=false
SKIP_VERSION=false
BETA=false

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Start the timer
START_TIME=$(date +%s)

# Functions
timestamp() {
    date +"%H:%M:%S"
}

log() {
    echo -e "[$(timestamp)] ${YELLOW}$1${NC}"
}

success() {
    echo -e "[$(timestamp)] ${GREEN}$1${NC}"
}

error() {
    echo -e "[$(timestamp)] ${RED}$1${NC}"
    echo "[$(timestamp)] $1" >> "$ERROR_LOG_FILE"
    exit 1
}

show_help() {
    cat <<EOF
Usage: $0 [options] [target]

Options:
  --verbose           Show detailed logs for each command
  --skip-analyze      Skip the Flutter analyze step
  --skip-version      Skip incrementing the version
  --beta              Deploy to closed testing (TestFlight for iOS, alpha track for Android)
  -h, --help          Show this help message

Targets:
  android             Deploy only for Android
  ios                 Deploy only for iOS
  all (default)       Deploy for both Android and iOS

Examples:
  $0 android
  $0 --skip-analyze ios
  $0 --verbose --skip-version
  $0 --beta all
  $0 --beta ios
EOF
    exit 0
}

check_dependencies() {
    log "🔍 Checking dependencies..."
    command -v flutter >/dev/null 2>&1 || error "Flutter is not installed. Please install it."
    command -v fastlane >/dev/null 2>&1 || error "Fastlane is not installed. Please install it."
    success "✅ Dependencies are installed"
}

flutter_clean() {
    log "🧹 Cleaning the project..."
    if ! flutter clean > /dev/null 2>&1; then
        error "❌ Error during 'flutter clean'"
    fi
    success "✅ Cleaning completed"
}

flutter_pub_get() {
    log "📦 Fetching dependencies..."
    if ! flutter pub get > /dev/null 2>&1; then
        error "❌ Error during 'flutter pub get'"
    fi
    success "✅ Dependencies fetched"
}

flutter_build_runner() {
    log "🔄 Running build runner..."
    if ! flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1; then
        error "❌ Error during 'flutter build_runner'"
    fi
    success "✅ Build runner completed"
}

flutter_gen_l10n() {
    log "🌍 Generating localization files..."
    if ! flutter gen-l10n > /dev/null 2>&1; then
        error "❌ Error during 'flutter gen-l10n'"
    fi
    success "✅ Localization generation completed"
}

flutter_analyze() {
    if [ "$SKIP_ANALYZE" = true ]; then
        log "🚫 Skipping flutter analyze as requested."
        return
    fi

    log "🛠️ Analyzing code..."
    if ! flutter analyze > /dev/null 2>&1; then
        error "❌ Code analysis failed"
    fi
    success "✅ Code analysis completed"
}

flutter_tests() {
    log "🧪 Running tests..."
    if ! flutter test > /dev/null 2>&1; then
        error "❌ Tests failed"
    fi
    success "✅ Tests completed"
}

increment_version() {
    if [ "$SKIP_VERSION" = true ]; then
        log "🚫 Skipping version increment as requested."
        return
    fi

    log "📈 Incrementing version..."
    VERSION=$(grep 'version: ' pubspec.yaml | sed 's/version: //' | tr -d '\n' | tr -d '\r')
    MAJOR=$(echo "$VERSION" | awk -F. '{print $1}')
    MINOR=$(echo "$VERSION" | awk -F. '{print $2}')
    PATCH=$(echo "$VERSION" | awk -F. '{print $3}' | awk -F+ '{print $1}')
    BUILD=$(echo "$VERSION" | awk -F+ '{print $2}')
    PATCH=$((PATCH + 1))
    BUILD=$((BUILD + 1))
    NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"
    if ! sed -i '' "s/version: $VERSION/version: $NEW_VERSION/" pubspec.yaml; then
        error "❌ Error incrementing version"
    fi
    success "✅ Version updated from $VERSION to $NEW_VERSION"
}

deploy_android() {
    log "🚀 Deploying Android..."
    if ! (cd android && $FASTLANE_ANDROID_COMMAND > /dev/null 2>&1); then
        error "❌ Error during Android deployment"
    fi
    success "✅ Android deployment completed"
}

deploy_ios() {
    log "🚀 Deploying iOS..."
    if ! (cd ios && $FASTLANE_IOS_COMMAND > /dev/null 2>&1); then
        error "❌ Error during iOS deployment"
    fi
    success "✅ iOS deployment completed"
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        --skip-analyze)
            SKIP_ANALYZE=true
            ;;
        --skip-version)
            SKIP_VERSION=true
            ;;
        --beta)
            BETA=true
            ;;
        -h|--help)
            show_help
            ;;
        *)
            TARGET=$arg
            ;;
    esac
done

if [ -z "$TARGET" ]; then
    TARGET="all"
fi

# Beta mode: switch to beta fastlane lanes
if [ "$BETA" = true ]; then
    FASTLANE_ANDROID_COMMAND="fastlane beta"
    FASTLANE_IOS_COMMAND="fastlane beta"
    log "🧪 Beta mode enabled — deploying to closed testing"
fi

# Verbose mode
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Main script
check_dependencies

# Run Flutter preparation steps
flutter_clean
flutter_pub_get
flutter_build_runner
flutter_gen_l10n
flutter_analyze
flutter_tests
increment_version

# Run deployment
case $TARGET in
    "android")
        deploy_android
        ;;
    "ios")
        deploy_ios
        ;;
    "all")
        deploy_android &
        deploy_ios &
        wait
        ;;
    *)
        error "❌ Error: Invalid target '$TARGET'"
        ;;
esac

# Calculate and print total time
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED_TIME / 60))
SECONDS=$((ELAPSED_TIME % 60))
success "⏱️ Total time: ${MINUTES}m ${SECONDS}s"