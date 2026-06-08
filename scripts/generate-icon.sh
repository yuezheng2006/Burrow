#!/usr/bin/env bash
# Render AppIcon.appiconset PNGs from Resources/IconSource.png (1024×1024 master).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MASTER="$ROOT/Resources/IconSource.png"
DEST="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"

[[ -f "$MASTER" ]] || { echo "missing master icon: $MASTER"; exit 1; }

declare -a SIZES=(
  "16:icon_16.png"
  "32:icon_16@2x.png"
  "32:icon_32.png"
  "64:icon_32@2x.png"
  "128:icon_128.png"
  "256:icon_128@2x.png"
  "256:icon_256.png"
  "512:icon_256@2x.png"
  "512:icon_512.png"
  "1024:icon_512@2x.png"
)

for spec in "${SIZES[@]}"; do
  size="${spec%%:*}"
  name="${spec##*:}"
  sips -z "$size" "$size" "$MASTER" --out "$DEST/$name" >/dev/null
done

echo "Generated ${#SIZES[@]} icon sizes in $DEST"
