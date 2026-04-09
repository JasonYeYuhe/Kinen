#!/bin/bash
set -euo pipefail

# Kinen App Store Build Script
# Usage: ./scripts/build-appstore.sh [ios|macos|both]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME_MAC="Kinen"
SCHEME_IOS="KinenIOS"

cd "$PROJECT_DIR"

echo "🧹 Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "⚙️  Generating Xcode project..."
xcodegen generate

TARGET="${1:-both}"

# ============================================================
# macOS Archive
# ============================================================
build_macos() {
    echo ""
    echo "🖥  Building macOS archive..."
    echo "================================"

    xcodebuild archive \
        -scheme "$SCHEME_MAC" \
        -destination "generic/platform=macOS" \
        -archivePath "$BUILD_DIR/Kinen-macOS.xcarchive" \
        -configuration Release \
        CODE_SIGN_IDENTITY="Apple Distribution" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM=KHMK6Q3L3K \
        2>&1 | tail -5

    if [ -d "$BUILD_DIR/Kinen-macOS.xcarchive" ]; then
        echo "✅ macOS archive created: $BUILD_DIR/Kinen-macOS.xcarchive"
    else
        echo "❌ macOS archive failed"
        exit 1
    fi
}

# ============================================================
# iOS Archive
# ============================================================
build_ios() {
    echo ""
    echo "📱 Building iOS archive..."
    echo "================================"

    xcodebuild archive \
        -scheme "$SCHEME_IOS" \
        -destination "generic/platform=iOS" \
        -archivePath "$BUILD_DIR/Kinen-iOS.xcarchive" \
        -configuration Release \
        CODE_SIGN_IDENTITY="Apple Distribution" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM=KHMK6Q3L3K \
        2>&1 | tail -5

    if [ -d "$BUILD_DIR/Kinen-iOS.xcarchive" ]; then
        echo "✅ iOS archive created: $BUILD_DIR/Kinen-iOS.xcarchive"
    else
        echo "❌ iOS archive failed"
        exit 1
    fi
}

# ============================================================
# Export & Upload
# ============================================================
export_and_upload() {
    local PLATFORM="$1"
    local ARCHIVE_PATH="$BUILD_DIR/Kinen-${PLATFORM}.xcarchive"
    local EXPORT_PATH="$BUILD_DIR/export-${PLATFORM}"
    local PLIST="$SCRIPT_DIR/ExportOptions-${PLATFORM}.plist"

    if [ ! -f "$PLIST" ]; then
        echo "⚠️  No export options plist for $PLATFORM, skipping upload"
        echo "   Create $PLIST to enable automatic upload"
        return
    fi

    echo ""
    echo "📦 Exporting $PLATFORM for App Store..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$PLIST" \
        2>&1 | tail -3

    echo "✅ $PLATFORM export complete: $EXPORT_PATH"
}

# ============================================================
# Main
# ============================================================
case "$TARGET" in
    macos)
        build_macos
        export_and_upload "macOS"
        ;;
    ios)
        build_ios
        export_and_upload "iOS"
        ;;
    both)
        build_macos
        build_ios
        export_and_upload "macOS"
        export_and_upload "iOS"
        ;;
    *)
        echo "Usage: $0 [ios|macos|both]"
        exit 1
        ;;
esac

echo ""
echo "🎉 Build complete!"
echo "   Archives in: $BUILD_DIR/"
echo ""
echo "Next steps:"
echo "  1. Open Xcode Organizer (Window → Organizer)"
echo "  2. Select the archive and click 'Distribute App'"
echo "  3. Choose 'App Store Connect' → Upload"
echo "  Or use: xcrun altool --upload-app -f <path>.ipa -u <apple-id>"
