#!/bin/bash

# Start the timer
START_TIME=$(date +%s)

# Function for Android deployment
deploy_android() {
    echo "🚀 Deploying Android..."
    if ! (cd android && fastlane deploy > /dev/null 2>&1); then
        echo "❌ Error during Android deployment"
        exit 1
    fi
    echo "✅ Android deployment completed"
}

# Function for iOS deployment
deploy_ios() {
    echo "🚀 Deploying iOS..."
    if ! (cd ios && fastlane release > /dev/null 2>&1); then
        echo "❌ Error during iOS deployment"
        exit 1
    fi
    echo "✅ iOS deployment completed"
}

# Check the passed arguments
if [ -z "$1" ]; then
    TARGET="all"
elif [ "$1" == "android" ]; then
    TARGET="android"
elif [ "$1" == "ios" ]; then
    TARGET="ios"
else
    echo "❌ Error: Invalid parameter. Use 'android', 'ios', or pass nothing to run both."
    exit 1
fi

# Flutter steps with hidden output
echo "🧹 Cleaning the project..."
if ! flutter clean > /dev/null 2>&1; then
    echo "❌ Error during 'flutter clean'"
    exit 1
fi
echo "✅ Cleaning completed"

echo "📦 Fetching dependencies..."
if ! flutter pub get > /dev/null 2>&1; then
    echo "❌ Error during 'flutter pub get'"
    exit 1
fi
echo "✅ Dependencies fetched"

echo "🔄 Running build runner..."
if ! flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1; then
    echo "❌ Error during 'flutter build_runner'"
    exit 1
fi
echo "✅ Build runner completed"

echo "🌍 Generating localization files..."
if ! flutter gen-l10n > /dev/null 2>&1; then
    echo "❌ Error during 'flutter gen-l10n'"
    exit 1
fi
echo "✅ Localization generation completed"

echo "🧪 Running tests..."
if ! flutter test > /dev/null 2>&1; then
    echo "❌ Tests failed"
    exit 1
fi
echo "✅ Tests completed"

# Increment version
echo "📈 Incrementing version..."
VERSION=$(grep 'version: ' pubspec.yaml | sed 's/version: //' | tr -d '\n' | tr -d '\r')
MAJOR=$(echo "$VERSION" | awk -F. '{print $1}')
MINOR=$(echo "$VERSION" | awk -F. '{print $2}')
PATCH=$(echo "$VERSION" | awk -F. '{print $3}' | awk -F+ '{print $1}')
BUILD=$(echo "$VERSION" | awk -F+ '{print $2}')
PATCH=$((PATCH + 1))
BUILD=$((BUILD + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"
sed -i '' "s/version: $VERSION/version: $NEW_VERSION/" pubspec.yaml
echo "✅ Version updated from $VERSION to $NEW_VERSION"

# Run deployment based on the target
if [ "$TARGET" == "android" ]; then
    deploy_android
elif [ "$TARGET" == "ios" ]; then
    deploy_ios
else
    deploy_android
    deploy_ios
fi

# Calculate and print the total time in minutes and seconds
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED_TIME / 60))
SECONDS=$((ELAPSED_TIME % 60))
echo ""
echo "⏱️ Total time: ${MINUTES}m ${SECONDS}s"