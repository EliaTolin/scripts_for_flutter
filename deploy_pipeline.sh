#!/bin/bash

# Configurable variables
FASTLANE_ANDROID_COMMAND="fastlane deploy"
FASTLANE_IOS_COMMAND="fastlane release"
PROJECT_PATH=$(pwd)
LOG_FILE="deploy.log"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Start the timer
START_TIME=$(date +%s)

# Functions
log() {
    echo -e "${YELLOW}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

error() {
    echo -e "${RED}$1${NC}"
    exit 1
}

check_dependencies() {
    command -v flutter >/dev/null 2>&1 || error "❌ Flutter is not installed. Please install it."
    command -v fastlane >/dev/null 2>&1 || error "❌ Fastlane is not installed. Please install it."
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

flutter_tests() {
    log "🧪 Running tests..."
    if ! flutter test > /dev/null 2>&1; then
        error "❌ Tests failed"
    fi
    success "✅ Tests completed"
}

increment_version() {
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

# Main script
check_dependencies

TARGET=$1
if [ -z "$TARGET" ]; then
    TARGET="all"
fi

# Run Flutter preparation steps
flutter_clean
flutter_pub_get
flutter_build_runner
flutter_gen_l10n
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