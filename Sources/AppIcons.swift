//
//  AppIcons.swift
//  Fuchen (拂尘)
//
//  Menu-bar template glyph — refined feather silhouette matching AppIcon.
//

import AppKit

enum AppIcons {
    /// Template menu-bar glyph: elegant feather + dust trail at 16×16.
    static let menuBar: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let cx = rect.midX + 0.5
            let feather = NSBezierPath()
            // Shaft
            feather.move(to: NSPoint(x: cx - 0.5, y: rect.minY + 2))
            feather.curve(to: NSPoint(x: cx + 1, y: rect.maxY - 2.5),
                          controlPoint1: NSPoint(x: cx - 1.5, y: rect.midY + 2),
                          controlPoint2: NSPoint(x: cx + 0.5, y: rect.maxY - 5))
            // Left barbs
            feather.move(to: NSPoint(x: cx, y: rect.maxY - 4))
            feather.curve(to: NSPoint(x: cx - 0.5, y: rect.minY + 3),
                          controlPoint1: NSPoint(x: cx - 5.5, y: rect.maxY - 8),
                          controlPoint2: NSPoint(x: cx - 4.5, y: rect.minY + 6))
            // Right barbs
            feather.move(to: NSPoint(x: cx + 0.5, y: rect.maxY - 5))
            feather.curve(to: NSPoint(x: cx + 1, y: rect.minY + 4),
                          controlPoint1: NSPoint(x: cx + 5, y: rect.maxY - 7),
                          controlPoint2: NSPoint(x: cx + 4, y: rect.minY + 7))
            feather.lineWidth = 1.25
            feather.lineCapStyle = .round
            feather.lineJoinStyle = .round
            NSColor.black.setStroke()
            feather.stroke()

            // Dust sparkle (reads at menu-bar scale)
            let dust = NSBezierPath(ovalIn: NSRect(x: cx + 3, y: rect.maxY - 5, width: 1.6, height: 1.6))
            NSColor.black.setFill()
            dust.fill()
            let dust2 = NSBezierPath(ovalIn: NSRect(x: cx + 5, y: rect.maxY - 3, width: 1.1, height: 1.1))
            dust2.fill()
            return true
        }
        img.isTemplate = true
        return img
    }()
}
