//
//  AppScannerTests.swift
//  FuchenTests
//

import XCTest
@testable import Fuchen

final class AppScannerTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("fuchen-appscan-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testReadInfoPlist_parsesDisplayNameAndBundleId() throws {
        let app = tempDir.appendingPathComponent("Demo.app")
        let contents = app.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleDisplayName": "演示应用",
            "CFBundleIdentifier": "dev.test.demo",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        let info = try XCTUnwrap(AppScanner.readInfoPlist(at: app.path))
        XCTAssertEqual(info.name, "演示应用")
        XCTAssertEqual(info.bundleId, "dev.test.demo")
    }

    func testScan_findsFixtureApp() throws {
        let appsDir = tempDir.appendingPathComponent("Applications")
        let app = appsDir.appendingPathComponent("Fast.app")
        let contents = app.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleName": "Fast",
            "CFBundleIdentifier": "dev.test.fast",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))

        let found = AppScanner.scan(directories: [appsDir.path])
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found[0].name, "Fast")
        XCTAssertEqual(found[0].bundleId, "dev.test.fast")
        XCTAssertEqual(found[0].sizeStr, "—")
    }

    func testParseSize_handlesDashAndUnits() {
        XCTAssertEqual(AppListParser.parseSize("—"), 0)
        XCTAssertEqual(AppListParser.parseSize("--"), 0)
        XCTAssertEqual(AppListParser.parseSize("12.5MB"), 12_582_912)
    }

    func testMerge_prefersFreshSizesByPath() {
        let old = InstalledApp(id: "a", name: "A", bundleId: "a", source: "App",
                               uninstallName: "a", path: "/Applications/A.app",
                               sizeStr: "—", sizeBytes: 0, lastUsed: nil)
        let fresh = InstalledApp(id: "a", name: "A", bundleId: "a", source: "Homebrew",
                                 uninstallName: "a", path: "/Applications/A.app",
                                 sizeStr: "10MB", sizeBytes: 10_485_760, lastUsed: nil)
        let merged = AppListParser.merge(existing: [old], fresh: [fresh])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].sizeStr, "10MB")
        XCTAssertEqual(merged[0].source, "Homebrew")
    }
}
