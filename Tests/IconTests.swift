//
//  IconTests.swift
//  FuchenTests
//

import XCTest

final class IconTests: XCTestCase {
    func testAppIconPngsExist() {
        let base = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
        let required = [
            "icon_512@2x.png",
            "icon_256@2x.png",
            "icon_128@2x.png",
        ]
        for name in required {
            let url = base.appendingPathComponent(name)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "missing \(name)")
        }
        let master = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/IconSource.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: master.path))
    }

    func testBuildIconScriptExists() {
        let script = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("scripts/build-icon.sh")
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path))
    }
}
