#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="MOME"
MOME_VERSION="${MOME_VERSION:-0.1.0}"
MOME_BUILD_NUMBER="${MOME_BUILD_NUMBER:-1}"
MOME_CODESIGN_IDENTITY="${MOME_CODESIGN_IDENTITY:--}"

# Validate Info.plist version fields before building.
[[ "$MOME_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][A-Za-z0-9.]+)?$ ]] || {
    echo "Invalid MOME_VERSION: $MOME_VERSION" >&2; exit 2;
}
[[ "$MOME_BUILD_NUMBER" =~ ^[0-9]+$ ]] || {
    echo "MOME_BUILD_NUMBER must be numeric" >&2; exit 2;
}
BUNDLE_ID="za.co.mome.devcenter"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building $APP_NAME (release)"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BIN_DIR/$APP_NAME" "$MACOS/$APP_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$MOME_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$MOME_BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
PLIST

# Ad-hoc signing is only for local development and CI validation.
# Official releases must use a Developer ID Application certificate, Hardened Runtime,
# and a trusted timestamp before Apple notarization.
if [[ "$MOME_CODESIGN_IDENTITY" == "-" ]]; then
    echo "==> Development build (ad-hoc signature; not for public app distribution)"
    codesign --force --sign - "$APP"
else
    [[ "$MOME_CODESIGN_IDENTITY" == "Developer ID Application:"* ]] || {
        echo "Public builds require a Developer ID Application certificate identity." >&2
        exit 3
    }
    codesign --force --options runtime --timestamp --sign "$MOME_CODESIGN_IDENTITY" "$APP"
fi
codesign --verify --deep --strict --verbose=2 "$APP"

echo "==> Built $APP"
echo "Open with: open '$APP'"
