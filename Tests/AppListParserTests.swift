//
//  AppListParserTests.swift
//  FuchenTests
//
//  Tests AppListParser utilities for parsing Mole's `mo uninstall --list`
//  JSON output and merging app lists. These are pure functions with no
//  I/O, so they're easy to test exhaustively.
//

import XCTest
@testable import Fuchen

final class AppListParserTests: XCTestCase {

    // MARK: - parseMoleRows

    func testParseMoleRows_validInput() {
        let rows: [[String: Any]] = [
            [
                "name": "Safari",
                "path": "/Applications/Safari.app",
                "bundle_id": "com.apple.Safari",
                "source": "System",
                "uninstall_name": "safari",
                "size": "150MB"
            ],
            [
                "name": "Xcode",
                "path": "/Applications/Xcode.app",
                "bundle_id": "com.apple.dt.Xcode",
                "source": "App",
                "uninstall_name": "xcode",
                "size": "12.5GB"
            ]
        ]

        let apps = AppListParser.parseMoleRows(rows)

        XCTAssertEqual(apps.count, 2)

        let safari = apps[0]
        XCTAssertEqual(safari.name, "Safari")
        XCTAssertEqual(safari.path, "/Applications/Safari.app")
        XCTAssertEqual(safari.bundleId, "com.apple.Safari")
        XCTAssertEqual(safari.source, "System")
        XCTAssertEqual(safari.uninstallName, "safari")
        XCTAssertEqual(safari.sizeStr, "150MB")

        let xcode = apps[1]
        XCTAssertEqual(xcode.name, "Xcode")
        XCTAssertEqual(xcode.sizeStr, "12.5GB")
    }

    func testParseMoleRows_missingRequiredFields_skipsRow() {
        let rows: [[String: Any]] = [
            ["name": "Valid", "path": "/Applications/Valid.app"],
            ["name": "MissingPath"],  // No path
            ["path": "/Applications/MissingName.app"]  // No name
        ]

        let apps = AppListParser.parseMoleRows(rows)

        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps[0].name, "Valid")
    }

    func testParseMoleRows_missingOptionalFields_usesDefaults() {
        let rows: [[String: Any]] = [
            ["name": "Minimal", "path": "/Applications/Minimal.app"]
        ]

        let apps = AppListParser.parseMoleRows(rows)

        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps[0].bundleId, "")
        XCTAssertEqual(apps[0].source, "App")
        XCTAssertEqual(apps[0].uninstallName, "Minimal")
        XCTAssertEqual(apps[0].sizeStr, "—")
    }

    func testParseMoleRows_emptyArray() {
        let apps = AppListParser.parseMoleRows([])
        XCTAssertTrue(apps.isEmpty)
    }

    // MARK: - merge

    func testMerge_emptyExisting_returnsFresh() {
        let fresh = [
            makeApp(name: "App1", path: "/Applications/App1.app"),
            makeApp(name: "App2", path: "/Applications/App2.app")
        ]

        let merged = AppListParser.merge(existing: [], fresh: fresh)

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(Set(merged.map { $0.name }), ["App1", "App2"])
    }

    func testMerge_updatesExistingByPath() {
        let existing = [
            makeApp(name: "OldName", path: "/Applications/App.app", sizeStr: "100MB")
        ]
        let fresh = [
            makeApp(name: "NewName", path: "/Applications/App.app", sizeStr: "150MB")
        ]

        let merged = AppListParser.merge(existing: existing, fresh: fresh)

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].name, "NewName", "should use fresh data")
        XCTAssertEqual(merged[0].sizeStr, "150MB")
    }

    func testMerge_preservesUnchanged() {
        let existing = [
            makeApp(name: "Unchanged", path: "/Applications/Unchanged.app"),
            makeApp(name: "Updated", path: "/Applications/Updated.app")
        ]
        let fresh = [
            makeApp(name: "Updated-New", path: "/Applications/Updated.app")
        ]

        let merged = AppListParser.merge(existing: existing, fresh: fresh)

        XCTAssertEqual(merged.count, 2)
        let names = Set(merged.map { $0.name })
        XCTAssertTrue(names.contains("Unchanged"))
        XCTAssertTrue(names.contains("Updated-New"))
    }

    func testMerge_addsNewApps() {
        let existing = [
            makeApp(name: "App1", path: "/Applications/App1.app")
        ]
        let fresh = [
            makeApp(name: "App1", path: "/Applications/App1.app"),
            makeApp(name: "App2", path: "/Applications/App2.app")
        ]

        let merged = AppListParser.merge(existing: existing, fresh: fresh)

        XCTAssertEqual(merged.count, 2)
        XCTAssertTrue(merged.contains { $0.name == "App2" })
    }

    // MARK: - parseSize

    func testParseSize_bytes() {
        XCTAssertEqual(AppListParser.parseSize("512B"), 512)
        XCTAssertEqual(AppListParser.parseSize("1024 B"), 1024)
    }

    func testParseSize_kilobytes() {
        XCTAssertEqual(AppListParser.parseSize("10KB"), 10240)
        XCTAssertEqual(AppListParser.parseSize("1.5 KB"), 1536)
    }

    func testParseSize_megabytes() {
        XCTAssertEqual(AppListParser.parseSize("100MB"), 104857600)
        XCTAssertEqual(AppListParser.parseSize("2.5 MB"), 2621440)
    }

    func testParseSize_gigabytes() {
        XCTAssertEqual(AppListParser.parseSize("5GB"), 5368709120)
        XCTAssertEqual(AppListParser.parseSize("1.2 GB"), 1288490188)
    }

    func testParseSize_terabytes() {
        XCTAssertEqual(AppListParser.parseSize("1TB"), 1099511627776)
        XCTAssertEqual(AppListParser.parseSize("0.5 TB"), 549755813888)
    }

    func testParseSize_caseInsensitive() {
        XCTAssertEqual(AppListParser.parseSize("10kb"), 10240)
        XCTAssertEqual(AppListParser.parseSize("5gB"), 5368709120)
    }

    func testParseSize_placeholder_returnsZero() {
        XCTAssertEqual(AppListParser.parseSize("—"), 0)
        XCTAssertEqual(AppListParser.parseSize("--"), 0)
        XCTAssertEqual(AppListParser.parseSize(""), 0)
    }

    func testParseSize_invalidFormat_returnsZero() {
        XCTAssertEqual(AppListParser.parseSize("invalid"), 0)
        XCTAssertEqual(AppListParser.parseSize("abc MB"), 0)
    }

    func testParseSize_whitespace() {
        XCTAssertEqual(AppListParser.parseSize("  100 MB  "), 104857600)
    }

    func testParseSize_noUnit_treatsAsBytes() {
        XCTAssertEqual(AppListParser.parseSize("1024"), 1024)
    }

    // MARK: - Helpers

    private func makeApp(name: String, path: String, sizeStr: String = "—") -> InstalledApp {
        return InstalledApp(
            id: path,
            name: name,
            bundleId: "",
            source: "App",
            uninstallName: name.lowercased(),
            path: path,
            sizeStr: sizeStr,
            sizeBytes: AppListParser.parseSize(sizeStr),
            lastUsed: nil
        )
    }
}
