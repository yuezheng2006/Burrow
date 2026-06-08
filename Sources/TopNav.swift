//
//  TopNav.swift
//  Fuchen
//
//  The floating top-centre nav: Fuchen mark + five lowercase tool tabs,
//  with Settings (gear) and History (clock) as utilities in the same
//  bar. One navigation model for the whole window — tools and the two
//  Fuchen extras are all just `Pane`s.
//

import SwiftUI
import AppKit

struct TopNav: View {
    @Binding var selected: Pane

    var body: some View {
        HStack(spacing: 8) {
            toolGroup
            utilityGroup
        }
    }

    private var toolGroup: some View {
        HStack(spacing: 2) {
            AppMark()
                .frame(width: 24, height: 24)
                .padding(.leading, 6)
                .padding(.trailing, 4)
            ForEach(Tool.navOrder) { tool in
                tab(tool)
            }
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.black.opacity(0.24)))
        .overlay(Capsule(style: .continuous).strokeBorder(Brand.hairline, lineWidth: 1))
    }

    private var utilityGroup: some View {
        HStack(spacing: 2) {
            LanguageToggle(compact: true)
                .padding(.horizontal, 4)
            utility("clock.arrow.circlepath", pane: .history)
            utility("gearshape", pane: .settings)
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.black.opacity(0.24)))
        .overlay(Capsule(style: .continuous).strokeBorder(Brand.hairline, lineWidth: 1))
    }

    private func tab(_ tool: Tool) -> some View {
        let isOn = selected == .tool(tool)
        return Button {
            withAnimation(.easeOut(duration: 0.16)) { selected = .tool(tool) }
        } label: {
            Text(tool.label)
                .font(Brand.mono(12, isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? Brand.textPrimary : Brand.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background { if isOn { Capsule(style: .continuous).fill(Brand.selectedChip) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func utility(_ symbol: String, pane: Pane) -> some View {
        let isOn = selected == pane
        return Button {
            withAnimation(.easeOut(duration: 0.16)) { selected = pane }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isOn ? Brand.textPrimary : Brand.textSecondary)
                .frame(width: 28, height: 26)
                .background { if isOn { Capsule(style: .continuous).fill(Brand.selectedChip) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// 拂尘 mark — matches AppIcon feather motif.
struct AppMark: View {
    var body: some View {
        Image(nsImage: appMarkImage)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
    }

    private var appMarkImage: NSImage {
        if let cached = AppMark.cached { return cached }
        let size = NSSize(width: 64, height: 64)
        let img = NSImage(size: size, flipped: false) { rect in
            // Dark teal disc
            let bg = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            NSColor(calibratedRed: 0.06, green: 0.14, blue: 0.12, alpha: 1).setFill()
            bg.fill()

            let cx = rect.midX + 1
            let feather = NSBezierPath()
            feather.move(to: NSPoint(x: cx - 2, y: rect.minY + 10))
            feather.curve(to: NSPoint(x: cx + 4, y: rect.maxY - 10),
                          controlPoint1: NSPoint(x: cx - 8, y: rect.midY + 4),
                          controlPoint2: NSPoint(x: cx + 2, y: rect.maxY - 18))
            feather.lineWidth = 3
            feather.lineCapStyle = .round
            NSColor(calibratedRed: 0.95, green: 0.83, blue: 0.55, alpha: 1).setStroke()
            feather.stroke()

            // Sparkle dots
            NSColor(calibratedRed: 0.95, green: 0.78, blue: 0.35, alpha: 0.9).setFill()
            NSBezierPath(ovalIn: NSRect(x: cx + 10, y: rect.maxY - 18, width: 4, height: 4)).fill()
            NSBezierPath(ovalIn: NSRect(x: cx + 16, y: rect.maxY - 12, width: 2.5, height: 2.5)).fill()
            return true
        }
        AppMark.cached = img
        return img
    }

    private static var cached: NSImage?
}
