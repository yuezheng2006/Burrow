#!/usr/bin/env bash
# Smoke-test AppScanner + AppListParser without Xcode.
set -euo pipefail
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path)
RUNNER=/tmp/fuchen-appscan-runner.swift
BIN=/tmp/fuchen-appscan-test

cat > "$RUNNER" <<'SWIFT'
import Foundation

struct InstalledApp {
    let id: String
    let name: String
    let bundleId: String
    let source: String
    let uninstallName: String
    let path: String
    let sizeStr: String
    let sizeBytes: Int64
    let lastUsed: Date?
}

@main
enum Runner {
    static func main() {
        let start = Date()
        let apps = AppScanner.scan()
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        print("scan_count=\(apps.count) scan_ms=\(ms)")
        assert(AppListParser.parseSize("12MB") > 0)
        assert(AppListParser.parseSize("—") == 0)
        print("parser_ok=1")
    }
}
SWIFT

swiftc -sdk "$SDK" -target arm64-apple-macos14.0 -O \
  Sources/AppScanner.swift "$RUNNER" -o "$BIN"
"$BIN"
