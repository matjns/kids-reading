#!/usr/bin/env bash
# Build Reading Quest on a Mac, or run the story and scoring tests.
# Usage:
#   ./build.sh        makes dist/Reading Quest.app and dist/ReadingQuest-mac-universal.zip
#   ./build.sh test   runs the logic tests (also works on Linux, with Swift installed)
set -euo pipefail

cd "$(dirname "$0")"

MODE="${1:-build}"
case "$MODE" in
  test)
    swift test
    exit 0
    ;;
  build)
    ;;
  *)
    echo "Usage: ./build.sh [test]" >&2
    exit 1
    ;;
esac

if [[ "$(uname)" != "Darwin" ]]; then
  echo "The app itself has to be built on a Mac. Run ./build.sh test to check the stories and scoring." >&2
  exit 1
fi

SDK="$(xcrun --sdk macosx --show-sdk-path)"
MIN="14.0"
VERSION="$(tr -d '[:space:]' < VERSION)"
APP_NAME="Reading Quest"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
BINARY_NAME="ReadingQuest"

if ! grep -q "<string>${VERSION}</string>" Packaging/Info.plist; then
  echo "VERSION (${VERSION}) does not match Packaging/Info.plist." >&2
  exit 1
fi

SWIFT_FILES=()
while IFS= read -r source_file; do
  SWIFT_FILES+=("$source_file")
done < <(find Sources/ReadingCore App -name '*.swift' -type f | sort)

if [[ ${#SWIFT_FILES[@]} -eq 0 ]]; then
  echo "No Swift source files were found." >&2
  exit 1
fi

compile_arch() {
  local arch="$1"
  local output="$2"
  swiftc \
    -sdk "$SDK" \
    -target "${arch}-apple-macosx${MIN}" \
    -swift-version 5 \
    -O \
    -parse-as-library \
    -module-name ReadingQuest \
    -o "$output" \
    "${SWIFT_FILES[@]}" \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework AVFAudio \
    -framework Combine
}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Passages" "$BUILD_DIR/slices"

compile_arch arm64 "$BUILD_DIR/slices/$BINARY_NAME-arm64"
compile_arch x86_64 "$BUILD_DIR/slices/$BINARY_NAME-x86_64"
lipo -create \
  "$BUILD_DIR/slices/$BINARY_NAME-arm64" \
  "$BUILD_DIR/slices/$BINARY_NAME-x86_64" \
  -output "$APP/Contents/MacOS/$BINARY_NAME"

cp Packaging/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp Sources/ReadingCore/Passages/*.json "$APP/Contents/Resources/Passages/"
cp Packaging/PrivacyInfo.xcprivacy "$APP/Contents/Resources/PrivacyInfo.xcprivacy"

iconutil -c icns Packaging/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - \
  --identifier "com.kidscomputer.reading" \
  --entitlements Packaging/ReadingQuest.entitlements \
  "$APP"

lipo -info "$APP/Contents/MacOS/$BINARY_NAME" | grep -q "arm64"
lipo -info "$APP/Contents/MacOS/$BINARY_NAME" | grep -q "x86_64"
codesign --verify --verbose=2 "$APP"
codesign -d --entitlements :- "$APP" 2>&1 | grep -q "com.apple.security.app-sandbox"

rm -rf dist
mkdir -p dist
cp -R "$APP" "dist/$APP_NAME.app"
cp README-mac.txt dist/README-mac.txt
(
  cd dist
  rm -f ReadingQuest-mac-universal.zip
  zip -r -y -q ReadingQuest-mac-universal.zip "$APP_NAME.app" README-mac.txt
)

echo "Built dist/$APP_NAME.app"
echo "Built dist/ReadingQuest-mac-universal.zip"
