//
//  L10nTests.swift
//  FuchenTests
//

import XCTest
@testable import Fuchen

final class L10nTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "app_language")
    }

    func testDefaultLanguageIsChinese() {
        XCTAssertEqual(Store.language, .zhHans)
        XCTAssertEqual(L10n.appName, "拂尘")
        XCTAssertEqual(L10n.settings, "设置")
        XCTAssertEqual(Tool.clean.title, "清理")
    }

    func testEnglishSwitch() {
        Store.language = .en
        XCTAssertEqual(L10n.appName, "Fuchen")
        XCTAssertEqual(L10n.settings, "Settings")
        XCTAssertEqual(Tool.clean.tagline, "Sweep the dust, breathe again.")
        XCTAssertEqual(L10n.healthRating(95), "Excellent")
    }

    func testHealthRatingBands() {
        Store.language = .zhHans
        XCTAssertEqual(L10n.healthRating(95), "优秀")
        XCTAssertEqual(L10n.healthRating(80), "良好")
        XCTAssertEqual(L10n.healthRating(65), "一般")
        XCTAssertEqual(L10n.healthRating(50), "较差")
        XCTAssertEqual(L10n.healthRating(10), "危险")
    }

    func testFormattedStrings() {
        Store.language = .zhHans
        XCTAssertEqual(L10n.appCount(12), "12 个应用")
        XCTAssertEqual(L10n.secondsAgo(5), "5 秒前")
        XCTAssertEqual(L10n.freedDetail(space: "1.2GB", items: "42"), "最多释放 1.2GB · 42 项")

        Store.language = .en
        XCTAssertEqual(L10n.updateCount(2), "2 updates")
        XCTAssertEqual(L10n.uninstallAppsTitle(1), "Uninstall 1 app?")
    }

    func testRetentionAndSampleLabels() {
        Store.language = .zhHans
        XCTAssertEqual(L10n.retentionLabel(days: 30), "30 天")
        XCTAssertEqual(L10n.sampleIntervalLabel(seconds: 60), "60 秒")
    }

    @MainActor
    func testLanguageStoreLiveSwitch() {
        LanguageStore.shared.setLanguage(.zhHans)
        XCTAssertEqual(LanguageStore.shared.current, .zhHans)
        XCTAssertEqual(L10n.settings, "设置")

        LanguageStore.shared.setLanguage(.en)
        XCTAssertEqual(LanguageStore.shared.current, .en)
        XCTAssertEqual(L10n.settings, "Settings")
    }
}
