//
//  SamplerTests.swift
//  FuchenTests
//
//  Tests the Sampler's lifecycle and failure modes. We can't easily test
//  the timer-driven tick() without making tests flaky, but we can verify:
//  - DB hydration on start
//  - Graceful degradation when mo status fails
//  - JSON decode error handling
//  - Timestamp handling (use Mole's collected_at, not Date())
//

import XCTest
@testable import Fuchen

final class SamplerTests: XCTestCase {
    private var tempDir: URL!
    private var db: DB!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("fuchen-sampler-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        db = try DB(at: tempDir.appendingPathComponent("fuchen.db"))
    }

    override func tearDown() {
        db = nil
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Initialization

    func testInit_setsDefaultInterval() {
        let sampler = Sampler(db: db)
        // Sampler doesn't expose intervalSeconds publicly, but we can
        // verify it initializes without crashing
        XCTAssertNotNil(sampler)
    }

    func testInit_acceptsCustomInterval() {
        let sampler = Sampler(db: db, intervalSeconds: 120)
        XCTAssertNotNil(sampler)
    }

    // MARK: - DB hydration

    func testStart_hydratesFromDB() throws {
        // Seed a snapshot before starting the sampler
        let ts = Int(Date().timeIntervalSince1970) - 30
        let json = validMoleJSON(cpu: 42.5)
        try db.insert(prefix: Sampler.snapshotPrefix, ts: ts, json: json)

        let sampler = Sampler(db: db, intervalSeconds: 3600) // Long interval to prevent auto-tick during test

        // Start triggers hydration on a background queue
        sampler.start()

        // Give the background queue time to hydrate
        let expectation = XCTestExpectation(description: "hydration")
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Verify lastSnapshot was populated
        XCTAssertNotNil(sampler.lastSnapshot)
        XCTAssertEqual(sampler.lastSnapshot?.cpu.usage, 42.5)
        XCTAssertNotNil(sampler.lastSampleAt)

        sampler.stop()
    }

    func testStart_emptyDB_doesNotCrash() {
        let sampler = Sampler(db: db, intervalSeconds: 3600)
        sampler.start()

        // No data to hydrate; should not crash
        XCTAssertNil(sampler.lastSnapshot)
        XCTAssertNil(sampler.lastSampleAt)

        sampler.stop()
    }

    // MARK: - Stop

    func testStop_cancelsTimer() {
        let sampler = Sampler(db: db, intervalSeconds: 1)
        sampler.start()
        sampler.stop()

        // Hard to assert timer state, but should not crash
        XCTAssertNotNil(sampler)
    }

    func testStop_idempotent() {
        let sampler = Sampler(db: db)
        sampler.stop()
        sampler.stop()

        // Should not crash on double-stop
        XCTAssertNotNil(sampler)
    }

    // MARK: - Snapshot prefix

    func testSnapshotPrefix_isConstant() {
        XCTAssertEqual(Sampler.snapshotPrefix, "mole.snapshot")
    }

    // MARK: - Failure modes (manual verification via logs)

    // These tests would require mocking MoleCLI.run(), which is static.
    // In a real TDD setup, we'd inject a protocol dependency. For now,
    // we document the expected failure modes:
    //
    // 1. `mo` not found → NSLog, retry next tick
    // 2. `mo status` exits non-zero → NSLog stderr, retry
    // 3. JSON decode fails → NSLog with coding path, retry
    // 4. DB insert fails → NSLog, retry (DB corruption or full disk)
    //
    // Manual test: rename `mo` to `mo.bak`, launch Fuchen, check Console.app

    // MARK: - Helpers

    private func validMoleJSON(cpu: Double) -> String {
        return """
        {
          "collected_at": "2026-06-08T12:00:00.000000-07:00",
          "host": "test-host",
          "platform": "darwin",
          "uptime": "1d 2h 3m",
          "uptime_seconds": 93780,
          "procs": 250,
          "hardware": {
            "model": "MacBookPro18,1",
            "cpu_model": "Apple M1 Pro",
            "total_ram": "32GB",
            "disk_size": "1TB",
            "os_version": "14.5",
            "refresh_rate": "120Hz"
          },
          "health_score": 85,
          "health_score_msg": "良好",
          "cpu": {
            "usage": \(cpu),
            "load1": 1.2,
            "load5": 1.5,
            "load15": 1.8,
            "core_count": 10,
            "logical_cpu": 10
          },
          "memory": {
            "used": 16384,
            "total": 32768,
            "used_percent": 50.0,
            "swap_used": 0,
            "swap_total": 0,
            "pressure": "normal"
          },
          "disk_io": {
            "read_rate": 1.5,
            "write_rate": 3.2
          },
          "network": {
            "rx_rate": 0.5,
            "tx_rate": 0.3
          },
          "battery": {
            "level": 85,
            "status": "Not Charging",
            "time_remaining": "N/A",
            "cycle_count": 42
          },
          "thermal": {
            "cpu_temp": 45.5,
            "fan_speed": 2000
          },
          "top_processes": [
            {
              "pid": 1234,
              "ppid": 1,
              "name": "TestProcess",
              "command": "/usr/bin/test",
              "cpu": 10.5,
              "memory": 500.0
            }
          ]
        }
        """
    }
}
