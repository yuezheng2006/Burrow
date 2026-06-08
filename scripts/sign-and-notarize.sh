#!/usr/bin/env bash
# Sign + notarize Fuchen.app (and optional DMG/ZIP) for Gatekeeper-clean installs.
#
# Required env:
#   CODESIGN_IDENTITY  — e.g. "Developer ID Application: Your Name (TEAMID)"
#
# For notarization (optional but recommended):
#   APPLE_ID           — Apple ID email
#   APPLE_APP_PASSWORD — app-specific password
#   APPLE_TEAM_ID      — 10-char team id
#
# Usage:
#   CODESIGN_IDENTITY="Developer ID Application: …" \
#     ./scripts/sign-and-notarize.sh build/Fuchen.app dist/Fuchen-0.5.1.dmg
#
set -euo pipefail
cd "$(dirname "$0")/.."

APP="${1:-build/Fuchen.app}"
shift || true
EXTRA=("$@")

[[ -d "$APP" ]] || { echo "app not found: $APP"; exit 1; }
[[ -n "${CODESIGN_IDENTITY:-}" ]] || {
  echo "Set CODESIGN_IDENTITY (Developer ID Application: …)"
  security find-identity -v -p codesigning || true
  exit 1
}

ENT="$PWD/Resources/Fuchen.entitlements"

echo "==> codesign $APP"
codesign --force --options runtime --timestamp \
  --entitlements "$ENT" \
  --sign "$CODESIGN_IDENTITY" \
  "$APP"

echo "==> verify signature"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl -a -t exec -vv "$APP" || true

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  ARCHIVE="build/notarize.zip"
  echo "==> notarize (upload)"
  ditto -c -k --keepParent "$APP" "$ARCHIVE"
  xcrun notarytool submit "$ARCHIVE" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

  echo "==> staple app"
  xcrun stapler staple "$APP"

  for path in "${EXTRA[@]}"; do
    [[ -f "$path" ]] || continue
    echo "==> notarize $path"
    SUB="build/notarize-$(basename "$path").zip"
    ditto -c -k --keepParent "$path" "$SUB" 2>/dev/null || zip -j "$SUB" "$path"
    xcrun notarytool submit "$SUB" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait
    xcrun stapler staple "$path" 2>/dev/null || true
  done
else
  echo "==> skip notarization (set APPLE_ID, APPLE_APP_PASSWORD, APPLE_TEAM_ID to enable)"
fi

echo "Done. Users can install without xattr when notarized."
