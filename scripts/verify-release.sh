#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${MOME_VERSION:-0.1.0}"
DMG="${1:-$ROOT/dist/MOME-$VERSION.dmg}"
MOUNT="$ROOT/dist/verify-mount"

test -f "$DMG" || { echo "DMG not found: $DMG"; exit 2; }

rm -rf "$MOUNT"
mkdir -p "$MOUNT"

cleanup() {
  hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || true
  rm -rf "$MOUNT"
}
trap cleanup EXIT

xcrun stapler validate "$DMG"
hdiutil attach "$DMG" -mountpoint "$MOUNT" -nobrowse -quiet

APP="$MOUNT/MOME.app"
test -d "$APP" || { echo "MOME.app missing from DMG"; exit 3; }

codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose=4 "$APP"

shasum -a 256 "$DMG" > "$DMG.sha256"
echo "==> Release artifact verified: $DMG"
