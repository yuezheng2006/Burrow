#!/usr/bin/env bash
# Build unsigned Burrow.app with swiftc (no full Xcode required).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
SDK=$(xcrun --show-sdk-path)
BIN=build/manual/Burrow
APP=build/Burrow.app
ZIP="dist/Burrow-${VERSION}.zip"
DMG="dist/Burrow-${VERSION}.dmg"
STAGE=build/dmg-staging

echo "==> compiling Burrow ${VERSION}"
mkdir -p build/manual
swiftc -sdk "$SDK" -target arm64-apple-macos14.0 -O -whole-module-optimization \
  $(find Sources -name '*.swift') -o "$BIN" \
  -framework AppKit -framework SwiftUI -framework Charts \
  -framework CoreServices -framework Network -framework CoreGraphics -lsqlite3

echo "==> packaging ${APP}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Burrow"
chmod +x "$APP/Contents/MacOS/Burrow"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Burrow' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier dev.caezium.Burrow' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Burrow' "$APP/Contents/Info.plist"
cp -R Resources/Assets.xcassets "$APP/Contents/Resources/"

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
hdiutil create -volname "Burrow ${VERSION}" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

ZIP_SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
DMG_SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
echo
echo "Built Burrow ${VERSION}"
echo "  zip      : ${ZIP}"
echo "  zip sha  : ${ZIP_SHA}"
echo "  dmg      : ${DMG}"
echo "  dmg sha  : ${DMG_SHA}"
