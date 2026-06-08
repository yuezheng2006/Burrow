#!/usr/bin/env bash
# Compile AppIcon.appiconset PNGs → AppIcon.icns (no Xcode actool required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET="$ROOT/build/Fuchen.iconset"
OUT="$ROOT/build/AppIcon.icns"

[[ -d "$SRC" ]] || { echo "missing $SRC"; exit 1; }

if [[ -f "$ROOT/Resources/IconSource.png" ]]; then
  "$ROOT/scripts/generate-icon.sh"
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"
cp "$SRC/icon_16.png"      "$ICONSET/icon_16x16.png"
cp "$SRC/icon_16@2x.png"   "$ICONSET/icon_16x16@2x.png"
cp "$SRC/icon_32.png"      "$ICONSET/icon_32x32.png"
cp "$SRC/icon_32@2x.png"   "$ICONSET/icon_32x32@2x.png"
cp "$SRC/icon_128.png"     "$ICONSET/icon_128x128.png"
cp "$SRC/icon_128@2x.png"  "$ICONSET/icon_128x128@2x.png"
cp "$SRC/icon_256.png"     "$ICONSET/icon_256x256.png"
cp "$SRC/icon_256@2x.png"  "$ICONSET/icon_256x256@2x.png"
cp "$SRC/icon_512.png"     "$ICONSET/icon_512x512.png"
cp "$SRC/icon_512@2x.png"  "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT"
echo "$OUT"
