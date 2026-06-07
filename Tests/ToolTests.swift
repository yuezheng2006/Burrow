//
//  ToolTests.swift
//  BurrowTests
//

import XCTest
@testable import Burrow

final class ToolTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "app_language")
    }

    func testNavOrderHasFiveTools() {
        XCTAssertEqual(Tool.navOrder.count, 5)
        XCTAssertEqual(Tool.navOrder.first, .clean)
        XCTAssertEqual(Tool.navOrder.last, .status)
    }

    func testChineseLabelsAndTitles() {
        Store.language = .zhHans
        XCTAssertEqual(Tool.clean.label, "清理")
        XCTAssertEqual(Tool.apps.title, "软件")
        XCTAssertEqual(Tool.optimize.tagline, "小调整，更顺畅。")
    }

    func testEnglishLabelsAndTitles() {
        Store.language = .en
        XCTAssertEqual(Tool.analyze.label, "analyze")
        XCTAssertEqual(Tool.status.title, "Status")
        XCTAssertEqual(Tool.apps.tagline, "Shed what you've outgrown.")
    }

    func testPaneScrimForUtilities() {
        let settings = Pane.settings
        let history = Pane.history
        XCTAssertNotEqual(settings, history)
        XCTAssertNotEqual(settings.scrim, Tool.clean.scrim)
    }
}
