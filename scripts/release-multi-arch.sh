#!/usr/bin/env bash
# Build Fuchen.app with per-arch packages (arm64, x86_64, universal).
# Produces separate .zip and .dmg for each architecture.
#
# Usage:
#   ./scripts/release-multi-arch.sh              # Build all three variants
#   SKIP_UNIVERSAL=1 ./scripts/release-multi-arch.sh  # Skip universal build
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
SDK=$(xcrun --show-sdk-path)
SKIP_UNIVERSAL="${SKIP_UNIVERSAL:-}"

SWIFT_SOURCES=()
while IFS= read -r f; do
  SWIFT_SOURCES+=("$f")
done < <(find Sources -name '*.swift' | sort)

SWIFT_FLAGS=(
  -sdk "$SDK"
  -O
  -whole-module-optimization
  "${SWIFT_SOURCES[@]}"
  -framework AppKit
  -framework SwiftUI
  -framework Charts
  -framework CoreServices
  -framework Network
  -framework CoreGraphics
  -lsqlite3
)

target_for_arch() {
  case "$1" in
    arm64)  echo "arm64-apple-macos14.0" ;;
    x86_64) echo "x86_64-apple-macos14.0" ;;
    *) echo "unsupported arch: $1" >&2; exit 1 ;;
  esac
}

build_arch_binary() {
  local arch=$1
  local bin_path="build/manual/Fuchen-${arch}"
  echo "==> compiling ${arch} binary" >&2
  swiftc "${SWIFT_FLAGS[@]}" -target "$(target_for_arch "$arch")" -o "$bin_path" 2>&1 | grep -v "^Sources/" >&2 || true
  echo "    $(lipo -info "$bin_path" | sed 's/^.*: //')" >&2
  echo "$bin_path"
}

package_app() {
  local arch=$1
  local bin_path=$2
  local suffix=$3
  local app="build/Fuchen-${suffix}.app"
  local zip="dist/Fuchen-${VERSION}-${suffix}.zip"
  local dmg="dist/Fuchen-${VERSION}-${suffix}.dmg"
  local stage="build/dmg-staging-${suffix}"

  echo "==> packaging ${app} (${arch})"
  rm -rf "$app"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$bin_path" "$app/Contents/MacOS/Fuchen"
  chmod +x "$app/Contents/MacOS/Fuchen"
  cp Resources/Info.plist "$app/Contents/Info.plist"

  # Inject bundle metadata
  /usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Fuchen' "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier dev.yuezheng2006.Fuchen' "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName Fuchen' "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName 拂尘' "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$app/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile AppIcon' "$app/Contents/Info.plist"
  cp build/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"

  # Ad-hoc sign (fixes broken linker signature after resource copy)
  codesign --force --deep --sign - "$app" >/dev/null 2>&1

  # Create zip
  rm -f "$zip"
  ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"

  # Create dmg
  rm -f "$dmg"
  rm -rf "$stage"
  mkdir -p "$stage"
  cp -R "$app" "$stage/"
  ln -s /Applications "$stage/Applications"
  hdiutil create -volname "Fuchen ${VERSION} (${suffix})" -srcfolder "$stage" -ov -format UDZO "$dmg" >/dev/null
  rm -rf "$stage"

  local zip_sha=$(shasum -a 256 "$zip" | awk '{print $1}')
  local dmg_sha=$(shasum -a 256 "$dmg" | awk '{print $1}')
  local zip_size=$(du -h "$zip" | awk '{print $1}')
  local dmg_size=$(du -h "$dmg" | awk '{print $1}')

  echo "    zip: ${zip} (${zip_size})"
  echo "         sha256: ${zip_sha}"
  echo "    dmg: ${dmg} (${dmg_size})"
  echo "         sha256: ${dmg_sha}"
  echo
}

# Build icon once
echo "==> building AppIcon.icns"
mkdir -p build
chmod +x scripts/build-icon.sh
scripts/build-icon.sh >/dev/null

# Compile per-arch binaries
echo "==> building Fuchen ${VERSION} (multi-arch)"
mkdir -p build/manual dist

ARM64_BIN=$(build_arch_binary arm64)
X86_64_BIN=$(build_arch_binary x86_64)

# Package arm64 variant
package_app "arm64" "$ARM64_BIN" "arm64"

# Package x86_64 variant
package_app "x86_64" "$X86_64_BIN" "x86_64"

# Package universal variant
if [[ -z "$SKIP_UNIVERSAL" ]]; then
  echo "==> creating universal binary"
  UNIVERSAL_BIN="build/manual/Fuchen-universal"
  lipo -create "$ARM64_BIN" "$X86_64_BIN" -output "$UNIVERSAL_BIN"
  echo "    $(lipo -info "$UNIVERSAL_BIN" | sed 's/^.*: //')"
  package_app "arm64 x86_64" "$UNIVERSAL_BIN" "universal"
fi

echo "========================================"
echo "Built Fuchen ${VERSION} - Multi-arch packages"
echo "========================================"
ls -lh dist/Fuchen-${VERSION}-*.{zip,dmg} 2>/dev/null | awk '{print $9, "("$5")"}'
echo
echo "✓ arm64 package:      optimized for Apple Silicon (M1/M2/M3)"
echo "✓ x86_64 package:     optimized for Intel Macs"
if [[ -z "$SKIP_UNIVERSAL" ]]; then
  echo "✓ universal package:  compatible with both architectures"
fi
echo
echo "Upload these to GitHub Releases with:"
echo "  gh release create v${VERSION} dist/Fuchen-${VERSION}-*.zip dist/Fuchen-${VERSION}-*.dmg"
echo
if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  echo "Note: unsigned builds — set CODESIGN_IDENTITY + notarization env for production."
  echo "See docs/SIGNING.md"
fi
