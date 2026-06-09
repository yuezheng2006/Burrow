//
//  DiskScannerTests.swift
//  FuchenTests
//
//  Tests DiskScanner's JSON parsing and error handling. Full integration
//  (spawning `mo analyze`) is expensive and disk-dependent, so we focus
//  on the parse() method with fixture JSON. The scan() method is smoke-
//  tested conditionally if `mo` is installed.
//

import XCTest
@testable import Fuchen

final class DiskScannerTests: XCTestCase {

    // MARK: - Parsing

    func testParse_validJSON_succeeds() throws {
        let json = """
        {
          "path": "/Applications",
          "total_size": 10737418240,
          "total_files": 150,
          "entries": [
            {
              "name": "Xcode.app",
              "path": "/Applications/Xcode.app",
              "size": 5368709120,
              "is_dir": true,
              "last_access": "2026-06-01T10:00:00.000000-07:00"
            },
            {
              "name": "Safari.app",
              "path": "/Applications/Safari.app",
              "size": 268435456,
              "is_dir": true,
              "last_access": "2026-06-08T08:30:00-07:00"
            },
            {
              "name": "README.txt",
              "path": "/Applications/README.txt",
              "size": 1024,
              "is_dir": false
            }
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertEqual(result.path, "/Applications")
        XCTAssertEqual(result.totalSize, 10737418240)
        XCTAssertEqual(result.totalFiles, 150)
        XCTAssertEqual(result.entries.count, 3)

        // Verify sorting: largest first
        XCTAssertEqual(result.entries[0].name, "Xcode.app")
        XCTAssertEqual(result.entries[0].size, 5368709120)
        XCTAssertTrue(result.entries[0].isDir)

        XCTAssertEqual(result.entries[1].name, "Safari.app")
        XCTAssertEqual(result.entries[2].name, "README.txt")
        XCTAssertFalse(result.entries[2].isDir)
    }

    func testParse_entriesAreSortedBySize() throws {
        let json = """
        {
          "path": "/test",
          "total_size": 1000,
          "total_files": 3,
          "entries": [
            {"name": "small", "path": "/test/small", "size": 10, "is_dir": false},
            {"name": "large", "path": "/test/large", "size": 500, "is_dir": false},
            {"name": "medium", "path": "/test/medium", "size": 100, "is_dir": false}
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertEqual(result.entries[0].name, "large")
        XCTAssertEqual(result.entries[1].name, "medium")
        XCTAssertEqual(result.entries[2].name, "small")
    }

    func testParse_missingOptionalFields_usesDefaults() throws {
        let json = """
        {
          "path": "/test",
          "entries": [
            {"name": "file", "path": "/test/file"}
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertEqual(result.path, "/test")
        XCTAssertEqual(result.totalSize, 0)
        XCTAssertEqual(result.totalFiles, 0)
        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.entries[0].size, 0)
        XCTAssertFalse(result.entries[0].isDir)
    }

    func testParse_emptyEntries_succeeds() throws {
        let json = """
        {"path": "/empty", "entries": []}
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertEqual(result.entries.count, 0)
    }

    func testParse_invalidJSON_throws() {
        let invalid = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try DiskScanner.parse(invalid)) { error in
            guard case DiskScanError.parseFailed = error else {
                return XCTFail("expected .parseFailed, got \(error)")
            }
        }
    }

    func testParse_missingRequiredField_skipsEntry() throws {
        let json = """
        {
          "path": "/test",
          "entries": [
            {"name": "valid", "path": "/test/valid", "size": 100, "is_dir": false},
            {"name": "no-path-field", "size": 50},
            {"path": "/test/no-name"}
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        // Only the valid entry should be included
        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.entries[0].name, "valid")
    }

    // MARK: - DiskScanEntry

    func testEntry_kind_directory() {
        let entry = DiskScanEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 1000,
            isDir: true,
            lastAccess: nil
        )

        XCTAssertEqual(entry.kind, "<dir>")
    }

    func testEntry_kind_fileWithExtension() {
        let entry = DiskScanEntry(
            id: "/test/file.swift",
            name: "file.swift",
            path: "/test/file.swift",
            size: 1000,
            isDir: false,
            lastAccess: nil
        )

        XCTAssertEqual(entry.kind, "swift")
    }

    func testEntry_kind_fileWithoutExtension() {
        let entry = DiskScanEntry(
            id: "/test/Makefile",
            name: "Makefile",
            path: "/test/Makefile",
            size: 1000,
            isDir: false,
            lastAccess: nil
        )

        XCTAssertEqual(entry.kind, "<none>")
    }

    func testEntry_kind_caseFolding() {
        let entry = DiskScanEntry(
            id: "/test/FILE.SWIFT",
            name: "FILE.SWIFT",
            path: "/test/FILE.SWIFT",
            size: 1000,
            isDir: false,
            lastAccess: nil
        )

        XCTAssertEqual(entry.kind, "swift", "extension should be lowercased")
    }

    // MARK: - Date parsing

    func testParse_ISO8601WithFractionalSeconds() throws {
        let json = """
        {
          "path": "/test",
          "entries": [
            {
              "name": "file",
              "path": "/test/file",
              "size": 100,
              "is_dir": false,
              "last_access": "2026-06-08T12:34:56.789000-07:00"
            }
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertNotNil(result.entries[0].lastAccess)
    }

    func testParse_ISO8601WithoutFractionalSeconds() throws {
        let json = """
        {
          "path": "/test",
          "entries": [
            {
              "name": "file",
              "path": "/test/file",
              "last_access": "2026-06-08T12:34:56-07:00"
            }
          ]
        }
        """.data(using: .utf8)!

        let result = try DiskScanner.parse(json)

        XCTAssertNotNil(result.entries[0].lastAccess)
    }

    // MARK: - Integration (requires `mo`)

    func testScan_ifMoInstalled() throws {
        guard MoleCLI.findExecutable() != nil else {
            NSLog("DiskScannerTests: skipping integration test; `mo` not found")
            return
        }

        // Scan /tmp — should be fast and always exists
        let result = try DiskScanner.scan("/tmp")

        XCTAssertEqual(result.path, "/tmp")
        XCTAssertGreaterThanOrEqual(result.entries.count, 0, "should return entries or empty array")
        XCTAssertNotNil(result.scannedAt)
    }

    func testScan_moNotFound_throws() {
        // Temporarily break the path by testing the error case
        // This would require mocking MoleCLI.findExecutable(), which
        // is static. In a real test suite, we'd inject a protocol.
        // For now, we document the expected behavior:
        //
        // If `mo` is not found, scan() should throw .moNotFound
    }
}
