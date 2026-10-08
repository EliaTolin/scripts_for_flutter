#!/bin/bash

# Configurable variables
FASTLANE_ANDROID_COMMAND="fastlane deploy"
FASTLANE_IOS_COMMAND="fastlane release"
PROJECT_PATH=$(pwd)
# Command output goes to one log file per step, outside the project so that
# `flutter clean` does not delete it and git does not see it.
LOG_DIR=$(mktemp -d -t deploy_flutter)
ERROR_LOG_FILE="$LOG_DIR/errors.log"
# Lines of a failed step's log shown in the terminal
FAILURE_TAIL_LINES=40
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

# Runs a command and saves its output to $LOG_DIR/<name>.log.
# On failure prints the end of the log, so the cause is visible without
# rerunning in verbose mode. With --verbose the output is also shown live.
run_step() {
    local name=$1
    shift
    local step_log="$LOG_DIR/$name.log"
    local status
    if [ "$VERBOSE" = true ]; then
        "$@" 2>&1 | tee "$step_log"
        status=${PIPESTATUS[0]}
    else
        "$@" > "$step_log" 2>&1
        status=$?
    fi
    if [ $status -ne 0 ]; then
        echo -e "${RED}--- last $FAILURE_TAIL_LINES lines of $step_log ---${NC}"
        tail -n "$FAILURE_TAIL_LINES" "$step_log"
        echo -e "${RED}--- end of log ---${NC}"
    fi
    return $status
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
    if ! run_step clean flutter clean; then
        error "❌ Error during 'flutter clean'"
    fi
    success "✅ Cleaning completed"
}

flutter_pub_get() {
    log "📦 Fetching dependencies..."
    if ! run_step pub_get flutter pub get; then
        error "❌ Error during 'flutter pub get'"
    fi
    success "✅ Dependencies fetched"
}

flutter_build_runner() {
    log "🔄 Running build runner..."
    if ! run_step build_runner dart run build_runner build --delete-conflicting-outputs; then
        error "❌ Error during 'flutter build_runner'"
    fi
    success "✅ Build runner completed"
}

flutter_gen_l10n() {
    log "🌍 Generating localization files..."
    if ! run_step gen_l10n flutter gen-l10n; then
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
    if ! run_step analyze flutter analyze; then
        error "❌ Code analysis failed"
    fi
    success "✅ Code analysis completed"
}

flutter_tests() {
    log "🧪 Running tests..."
    if ! run_step test flutter test; then
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
    if ! (cd android && run_step android $FASTLANE_ANDROID_COMMAND); then
        error "❌ Error during Android deployment"
    fi
    success "✅ Android deployment completed"
}

deploy_ios() {
    log "🚀 Deploying iOS..."
    if ! (cd ios && run_step ios $FASTLANE_IOS_COMMAND); then
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
if [ ! -f "$PROJECT_PATH/pubspec.yaml" ]; then
    error "❌ Error: 'pubspec.yaml' not found in the current directory."
fi
log "📝 Logs: $LOG_DIR"
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
        # Each platform runs in its own subshell: `error` there only ends the
        # subshell, so the exit status of every job must be checked here.
        deploy_android &
        ANDROID_PID=$!
        deploy_ios &
        IOS_PID=$!
        FAILED=""
        wait $ANDROID_PID || FAILED="$FAILED Android"
        wait $IOS_PID || FAILED="$FAILED iOS"
        if [ -n "$FAILED" ]; then
            error "❌ Deployment failed for:$FAILED (logs: $LOG_DIR)"
        fi
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