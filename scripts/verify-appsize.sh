#!/usr/bin/env bash
# Smoke-test AppSizeCalculator (du-based sizing).
set -euo pipefail
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path)
RUNNER=/tmp/fuchen-appsize-runner.swift
BIN=/tmp/fuchen-appsize-test

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
        let path = "/Applications/Fuchen.app"
        guard FileManager.default.fileExists(atPath: path) else {
            print("skip_no_fuchen=1")
            return
        }
        let bytes = AppSizeCalculator.allocatedBytes(at: path)
        assert(bytes > 0, "expected Fuchen.app size > 0, got \(bytes)")
        print("fuchen_bytes=\(bytes)")
        let apps = AppScanner.scan()
        var sized = 0
        let sample = Array(apps.prefix(8))
        for app in sample {
            if AppSizeCalculator.allocatedBytes(at: app.path) > 0 { sized += 1 }
        }
        assert(sized >= min(4, sample.count), "too few sized in sample: \(sized)/\(sample.count)")
        print("sample_sized=\(sized)/\(sample.count)")
    }
}
SWIFT

cat > /tmp/fuchen-fmt-stub.swift <<'SWIFT'
enum Fmt {
    static func bytes(_ n: Int64) -> String { "\(n) B" }
}
SWIFT

swiftc -sdk "$SDK" -target arm64-apple-macos14.0 -O \
  /tmp/fuchen-fmt-stub.swift Sources/AppScanner.swift Sources/AppSizeCalculator.swift "$RUNNER" -o "$BIN"
"$BIN"
