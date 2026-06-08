#!/usr/bin/env bash
# Install an unsigned Fuchen build to /Applications.
# Clears Gatekeeper quarantine and ad-hoc signs the bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_SRC="${1:-build/Fuchen.app}"
DEST="/Applications/Fuchen.app"

if [[ ! -d "$APP_SRC" ]]; then
  echo "Building Fuchen first…"
  ./scripts/release-swiftc.sh
  APP_SRC=build/Fuchen.app
fi

if ! command -v mo >/dev/null 2>&1 \
   && [[ ! -x /opt/homebrew/bin/mo ]] \
   && [[ ! -x /usr/local/bin/mo ]]; then
  echo "Mole CLI (mo) not found — install with: brew install mole"
  exit 1
fi

echo "==> installing ${APP_SRC} → ${DEST}"
sudo rm -rf "$DEST" 2>/dev/null || rm -rf "$DEST"
cp -R "$APP_SRC" "$DEST"
xattr -cr "$DEST"
codesign --force --deep --sign - "$DEST"

echo "==> launching Fuchen"
open "$DEST"
echo
echo "Fuchen installed. First launch opens the main window automatically."
echo "Later launches: click the chart icon in the menu bar (top-right)."
