#!/usr/bin/env bash
# Build Fuchen.app with swiftc. Signs + notarizes when CODESIGN_IDENTITY is set.
#
# By default produces a universal binary (arm64 + x86_64). Override with:
#   FUCHEN_ARCHS=arm64 ./scripts/release-swiftc.sh   # Apple Silicon only (faster local dev)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
SDK=$(xcrun --show-sdk-path)
BIN=build/manual/Fuchen
APP=build/Fuchen.app
ICNS=build/AppIcon.icns
ZIP="dist/Fuchen-${VERSION}.zip"
DMG="dist/Fuchen-${VERSION}.dmg"
STAGE=build/dmg-staging
FUCHEN_ARCHS="${FUCHEN_ARCHS:-arm64 x86_64}"

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
    *) echo "unsupported arch: $1 (use arm64 and/or x86_64)" >&2; exit 1 ;;
  esac
}

echo "==> compiling Fuchen ${VERSION} (${FUCHEN_ARCHS})"
mkdir -p build/manual
read -ra ARCH_LIST <<< "$FUCHEN_ARCHS"
ARCH_BINS=()
for arch in "${ARCH_LIST[@]}"; do
  arch_bin="build/manual/Fuchen-${arch}"
  echo "    ${arch} → ${arch_bin}"
  swiftc "${SWIFT_FLAGS[@]}" -target "$(target_for_arch "$arch")" -o "$arch_bin"
  ARCH_BINS+=("$arch_bin")
done

if [[ ${#ARCH_BINS[@]} -eq 1 ]]; then
  cp "${ARCH_BINS[0]}" "$BIN"
else
  echo "==> lipo universal binary → ${BIN}"
  lipo -create "${ARCH_BINS[@]}" -output "$BIN"
fi
lipo -info "$BIN"

echo "==> building AppIcon.icns"
chmod +x scripts/build-icon.sh
scripts/build-icon.sh >/dev/null

echo "==> packaging ${APP}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Fuchen"
chmod +x "$APP/Contents/MacOS/Fuchen"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Fuchen' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier dev.yuezheng2006.Fuchen' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Fuchen' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName 拂尘' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$APP/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile AppIcon' "$APP/Contents/Info.plist"
cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"

# swiftc linker-sign leaves a broken ad-hoc signature once resources are
# added; re-sign so Gatekeeper + spctl don't reject the bundle.
echo "==> ad-hoc signing ${APP}"
codesign --force --deep --sign - "$APP"

mkdir -p dist
rm -f "$ZIP"
echo "==> zipping ${ZIP}"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

rm -f "$DMG"
echo "==> creating ${DMG}"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Fuchen ${VERSION}" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

if [[ -n "${CODESIGN_IDENTITY:-}" && -n "${APPLE_ID:-}" ]]; then
  chmod +x scripts/sign-and-notarize.sh
  scripts/sign-and-notarize.sh "$APP" "$DMG" "$ZIP"
fi

ZIP_SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
DMG_SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
echo
echo "Built Fuchen ${VERSION} (universal: ${FUCHEN_ARCHS})"
echo "  binary   : $(lipo -info "$BIN" | sed 's/^.*: //')"
echo "  zip      : ${ZIP}"
echo "  zip sha  : ${ZIP_SHA}"
echo "  dmg      : ${DMG}"
echo "  dmg sha  : ${DMG_SHA}"
if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  echo
  echo "Note: unsigned build — set CODESIGN_IDENTITY + Apple notarization env to ship Gatekeeper-clean."
  echo "See docs/SIGNING.md"
fi
