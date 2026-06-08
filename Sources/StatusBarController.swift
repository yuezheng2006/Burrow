//
//  StatusBarController.swift
//  Fuchen
//
//  Owns the NSStatusItem and its popover. The popover is created
//  lazily on first click and reused; its NSHostingController holds
//  the SwiftUI `PopupView` bound to the Sampler (for live snapshot
//  data) and the AppDelegate (for the History / Cleanup / Settings
//  buttons that open windows).
//

import AppKit
import SwiftUI

final class StatusBarController {
    private let item: NSStatusItem
    private var popover: NSPopover?
    private let db: DB
    private let sampler: Sampler
    private weak var delegate: AppDelegate?

    init(db: DB, sampler: Sampler, delegate: AppDelegate) {
        self.db = db
        self.sampler = sampler
        self.delegate = delegate
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = self.item.button {
            button.image = AppIcons.menuBar
            button.action = #selector(self.handleClick(_:))
            button.target = self
        }
    }

    private func ensurePopover() -> NSPopover {
        if let popover { return popover }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentSize = NSSize(width: 334, height: 560)
        if let delegate {
            popover.contentViewController = HUDController(
                root: PopupView(db: db, sampler: sampler, delegate: delegate))
        }
        self.popover = popover
        return popover
    }

    @objc private func handleClick(_ sender: Any?) {
        guard let button = self.item.button else { return }
        let popover = ensurePopover()
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds,
                         of: button,
                         preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
