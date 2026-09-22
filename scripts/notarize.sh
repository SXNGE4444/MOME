#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${MOME_VERSION:-0.1.0}"
DMG="${1:-$ROOT/dist/MOME-$VERSION.dmg}"

: "${APPLE_ID:?APPLE_ID is required}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD is required}"

test -f "$DMG" || { echo "DMG not found: $DMG"; exit 2; }

echo "==> Submitting $(basename "$DMG") to Apple notarization"
xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo "==> Notarization complete"
