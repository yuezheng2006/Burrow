//
//  DarkAppearance.swift
//  Fuchen
//
//  Force dark Aqua everywhere — independent of macOS Light/Dark setting.
//

import AppKit

enum DarkAppearance {
    static let aqua = NSAppearance(named: .darkAqua)!

    static func applyAppWide() {
        NSApp.appearance = aqua
    }

    static func apply(to object: NSAppearanceCustomization) {
        object.appearance = aqua
    }
}
