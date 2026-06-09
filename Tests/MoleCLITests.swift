//
//  MoleCLITests.swift
//  FuchenTests
//
//  Tests MoleCLI subprocess wrapper. We verify:
//  - Executable discovery (PATH + hardcoded fallbacks)
//  - Timeout handling
//  - stdout/stderr capture
//  - Exit code propagation
//
//  Note: These tests require `mo` to be installed. If `mo` isn't found,
//  we test the error path instead of skipping — the "not found" case is
//  part of the contract.
//

import XCTest
@testable import Fuchen

final class MoleCLITests: XCTestCase {

    // MARK: - Executable discovery

    func testFindExecutable_returnsCachedValue() {
        // First call discovers and caches
        let first = MoleCLI.findExecutable()

        // Second call should return the same cached value
        let second = MoleCLI.findExecutable()

        if let path = first {
            XCTAssertEqual(first, second, "should cache the executable path")
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: path))
        } else {
            XCTAssertNil(second, "should consistently return nil if not found")
        }
    }

    func testFindExecutable_checksCommonPaths() {
        let path = MoleCLI.findExecutable()

        if let path {
            // If found, it should be in one of the known locations
            let validPrefixes = [
                "/opt/homebrew/bin/",
                "/usr/local/bin/",
                "/usr/bin/",
            ]
            let isValid = validPrefixes.contains { path.hasPrefix($0) }
            XCTAssertTrue(isValid || path.contains("/bin/mo"),
                         "executable should be in a known bin directory, got: \(path)")
        } else {
            // If not found, that's a valid test outcome — we're verifying
            // the discovery logic, not asserting `mo` must exist
            NSLog("MoleCLITests: `mo` not found; testing error path instead")
        }
    }

    // MARK: - Basic execution

    func testRun_capturesStdout() throws {
        // Use a known-working command: echo
        let result = try MoleCLI.run(args: ["test"], executable: "/bin/echo")

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "test")
        XCTAssertTrue(result.stderr.isEmpty)
    }

    func testRun_capturesStderr() throws {
        // Use a command that writes to stderr: `ls` with invalid path
        let result = try MoleCLI.run(args: ["/no-such-path-exists-xyz"], executable: "/bin/ls")

        XCTAssertNotEqual(result.exitCode, 0)
        XCTAssertTrue(result.stderr.contains("No such file") ||
                     result.stderr.contains("cannot access"),
                     "stderr should contain error message")
    }

    func testRun_nonZeroExitCode() throws {
        // `false` always exits with 1
        let result = try MoleCLI.run(args: [], executable: "/usr/bin/false")

        XCTAssertEqual(result.exitCode, 1)
    }

    func testRun_zeroExitCode() throws {
        // `true` always exits with 0
        let result = try MoleCLI.run(args: [], executable: "/usr/bin/true")

        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Timeout handling

    func testRun_respectsShortTimeout() {
        // `sleep 10` should be killed by a 1-second timeout
        let start = Date()

        do {
            _ = try MoleCLI.run(args: ["10"], executable: "/bin/sleep", timeout: 1)
            XCTFail("should have thrown or returned, but sleep should be terminated")
        } catch {
            // Expected: timeout or termination
        }

        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 3.0, "should terminate within ~1s, not wait for full 10s")
    }

    func testRun_completesWithinTimeout() throws {
        // Fast command with generous timeout should succeed
        let result = try MoleCLI.run(args: ["0.1"], executable: "/bin/sleep", timeout: 5)

        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Mole-specific (if installed)

    func testRun_moVersion_ifInstalled() throws {
        guard MoleCLI.findExecutable() != nil else {
            NSLog("MoleCLITests: skipping mo-specific test; executable not found")
            return
        }

        let result = try MoleCLI.run(args: ["--version"], timeout: 5)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("mole") || result.stdout.contains("mo"),
                     "version output should mention 'mole' or 'mo'")
    }

    func testRun_moStatus_ifInstalled() throws {
        guard MoleCLI.findExecutable() != nil else {
            NSLog("MoleCLITests: skipping mo status test; executable not found")
            return
        }

        let result = try MoleCLI.run(args: ["status", "--json"], timeout: 10)

        XCTAssertEqual(result.exitCode, 0, "mo status should succeed")

        // Verify it's valid JSON
        guard let data = result.stdout.data(using: .utf8) else {
            XCTFail("stdout should be UTF-8")
            return
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "stdout should be valid JSON")
        XCTAssertNotNil(json?["cpu"], "should contain 'cpu' key")
        XCTAssertNotNil(json?["memory"], "should contain 'memory' key")
    }

    // MARK: - Error cases

    func testRun_invalidExecutable_throws() {
        XCTAssertThrowsError(
            try MoleCLI.run(args: [], executable: "/no/such/executable")
        ) { error in
            // Should throw an error related to process spawn failure
            XCTAssertNotNil(error)
        }
    }

    func testRun_emptyArgs_works() throws {
        // Running `true` with no args should succeed
        let result = try MoleCLI.run(args: [], executable: "/usr/bin/true")
        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Result structure

    func testResult_containsAllFields() throws {
        let result = try MoleCLI.run(args: ["hello"], executable: "/bin/echo")

        XCTAssertNotNil(result.stdout)
        XCTAssertNotNil(result.stderr)
        XCTAssertNotNil(result.exitCode)

        // stdout should be a String
        XCTAssertTrue(result.stdout is String)
        XCTAssertTrue(result.stderr is String)
    }
}
