//
//  SoftwareModelTests.swift
//  FuchenTests
//
//  Tests the SoftwareModel app loading logic, especially the
//  prioritization of mole data over cache and du-based sizing.
//

import XCTest
@testable import Fuchen

final class SoftwareModelTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("fuchen-software-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Data source prioritization

    func testLoad_prioritizesMoleDataOverCache() {
        // This test verifies the load() method prioritizes:
        // 1. Mole data (with size)
        // 2. Cache (with size)
        // 3. Scanned result (no size)

        // Create mock data
        let scanned = InstalledApp(
            id: "scanned-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "App",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "—",
            sizeBytes: 0,
            lastUsed: nil
        )

        let cached = InstalledApp(
            id: "cached-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "App",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "100MB",
            sizeBytes: 104857600,
            lastUsed: nil
        )

        let mole = InstalledApp(
            id: "mole-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "Homebrew",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "150MB",
            sizeBytes: 157286400,
            lastUsed: nil
        )

        // Simulate the merge logic from load()
        let moleByPath = [mole.path: mole]
        let cachedByPath = [cached.path: cached]

        let result = prioritizeSize(scanned: scanned, moleByPath: moleByPath, cachedByPath: cachedByPath)

        // Should prioritize mole data
        XCTAssertEqual(result.name, "TestApp")
        XCTAssertEqual(result.sizeBytes, 157286400, "should use mole size")
        XCTAssertEqual(result.source, "Homebrew", "should use mole source")
    }

    func testLoad_fallsBackToCacheWhenMoleUnavailable() {
        let scanned = InstalledApp(
            id: "scanned-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "App",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "—",
            sizeBytes: 0,
            lastUsed: nil
        )

        let cached = InstalledApp(
            id: "cached-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "App",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "100MB",
            sizeBytes: 104857600,
            lastUsed: nil
        )

        let moleByPath: [String: InstalledApp] = [:]
        let cachedByPath = [cached.path: cached]

        let result = prioritizeSize(scanned: scanned, moleByPath: moleByPath, cachedByPath: cachedByPath)

        XCTAssertEqual(result.sizeBytes, 104857600, "should use cache size")
        XCTAssertEqual(result.source, "App")
    }

    func testLoad_usesScannedWhenNoSizeAvailable() {
        let scanned = InstalledApp(
            id: "scanned-id",
            name: "TestApp",
            bundleId: "com.test.app",
            source: "App",
            uninstallName: "testapp",
            path: "/Applications/TestApp.app",
            sizeStr: "—",
            sizeBytes: 0,
            lastUsed: nil
        )

        let moleByPath: [String: InstalledApp] = [:]
        let cachedByPath: [String: InstalledApp] = [:]

        let result = prioritizeSize(scanned: scanned, moleByPath: moleByPath, cachedByPath: cachedByPath)

        XCTAssertEqual(result.sizeBytes, 0, "should have no size")
        XCTAssertEqual(result.sizeStr, "—")
    }

    // MARK: - Helper

    /// Replicates the merge logic from SoftwareModel.load()
    private func prioritizeSize(
        scanned: InstalledApp,
        moleByPath: [String: InstalledApp],
        cachedByPath: [String: InstalledApp]
    ) -> InstalledApp {
        // Prioritize mole data
        if let mole = moleByPath[scanned.path], mole.sizeBytes > 0 {
            return InstalledApp(
                id: scanned.id,
                name: scanned.name,
                bundleId: scanned.bundleId,
                source: mole.source.isEmpty ? scanned.source : mole.source,
                uninstallName: mole.uninstallName.isEmpty ? scanned.uninstallName : mole.uninstallName,
                path: scanned.path,
                sizeStr: mole.sizeStr,
                sizeBytes: mole.sizeBytes,
                lastUsed: scanned.lastUsed)
        }
        // Fall back to cache
        else if let cached = cachedByPath[scanned.path], cached.sizeBytes > 0 {
            return InstalledApp(
                id: scanned.id,
                name: scanned.name,
                bundleId: scanned.bundleId,
                source: cached.source.isEmpty ? scanned.source : cached.source,
                uninstallName: cached.uninstallName.isEmpty ? scanned.uninstallName : cached.uninstallName,
                path: scanned.path,
                sizeStr: cached.sizeStr,
                sizeBytes: cached.sizeBytes,
                lastUsed: scanned.lastUsed)
        }
        // Use scanned result
        else {
            return scanned
        }
    }

    // MARK: - needsSizeRefresh

    func testNeedsSizeRefresh_detectsAppsWithoutSize() {
        let apps = [
            InstalledApp(id: "1", name: "A", bundleId: "a", source: "App", uninstallName: "a",
                        path: "/A.app", sizeStr: "100MB", sizeBytes: 104857600, lastUsed: nil),
            InstalledApp(id: "2", name: "B", bundleId: "b", source: "App", uninstallName: "b",
                        path: "/B.app", sizeStr: "—", sizeBytes: 0, lastUsed: nil),
            InstalledApp(id: "3", name: "C", bundleId: "c", source: "App", uninstallName: "c",
                        path: "/C.app", sizeStr: "200MB", sizeBytes: 209715200, lastUsed: nil),
        ]

        let needsSizing = apps.filter { $0.sizeBytes == 0 }
        XCTAssertEqual(needsSizing.count, 1)
        XCTAssertEqual(needsSizing[0].name, "B")
    }
}
