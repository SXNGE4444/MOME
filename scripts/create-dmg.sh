#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${MOME_VERSION:-0.1.0}"
SIGN_IDENTITY="${MOME_SIGN_IDENTITY:--}"
APP="$ROOT/dist/MOME.app"
DMG="$ROOT/dist/MOME-$VERSION.dmg"
STAGING="$ROOT/dist/dmg-root"

test -d "$APP" || { echo "MOME.app not found. Run scripts/build-app.sh first."; exit 2; }

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/MOME.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "MOME $VERSION" -srcfolder "$STAGING" -ov -format UDZO "$DMG"

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
  codesign --verify --verbose=2 "$DMG"
fi

rm -rf "$STAGING"
echo "$DMG"
