//
//  AnalyzeView.swift
//  Fuchen
//
//  The Analyze tab — Fuchen's take on mole.fit's "Jupiter" disk map.
//  A squarified treemap of a directory (via `mo analyze --json`, the
//  existing DiskScanner + Treemap engine), a left rail of the biggest
//  children, a breadcrumb, and drill-in by click. Reveal / Trash live
//  in each block's context menu.
//

import SwiftUI
import AppKit

struct AnalyzeView: View {
    @StateObject private var model = AnalyzeModel()
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 232)
            Rectangle().fill(Brand.hairline).frame(width: 1)
            mainArea
        }
        .onAppear { if isActive { model.startIfNeeded() } }
        .onChange(of: isActive) { _, now in if now { model.startIfNeeded() } }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient circle (inspired by Burrow)
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Tool.analyze.accent.opacity(0.90), Tool.analyze.accent.opacity(0.15)],
                            center: .init(x: 0.42, y: 0.38),
                            startRadius: 2,
                            endRadius: 68
                        ))
                        .frame(width: 88, height: 88)
                        .shadow(color: Tool.analyze.accent.opacity(0.4), radius: 22)

                    VStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text(model.summaryLine)
                        .font(Brand.mono(11, .semibold))
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                    Text(model.usageLine)
                        .font(Brand.mono(9, .medium))
                        .foregroundStyle(Brand.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20).padding(.bottom, 18)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.02), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Entries list with better styling
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.entries.prefix(50).enumerated()), id: \.element.id) { idx, e in
                        sidebarRow(e, index: idx)
                        if idx < min(model.entries.count, 50) - 1 {
                            Divider()
                                .overlay(Color.black.opacity(0.12))
                                .padding(.leading, 40)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func sidebarRow(_ e: DiskScanEntry, index: Int) -> some View {
        let isSelected = model.crumbs.last?.path == e.path
        let sizeRatio = model.currentTotal > 0 ? Double(e.size) / Double(model.currentTotal) : 0

        Button { model.drill(into: e) } label: {
            HStack(spacing: 12) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)

                    Image(nsImage: AnalyzeIcons.icon(for: e))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.25), radius: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(e.name)
                        .font(Brand.sans(13, .medium))
                        .foregroundStyle(isSelected ? Tool.analyze.accent : Brand.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Size bar
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Tool.analyze.accent.opacity(0.6))
                            .frame(width: max(0, CGFloat(sizeRatio) * 40), height: 3)

                        Text(Fmt.bytes(e.size))
                            .font(Brand.mono(10, .medium))
                            .foregroundStyle(Brand.textTertiary)
                    }
                }

                Spacer(minLength: 6)

                if e.isDir {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Brand.textTertiary.opacity(0.7))
                }
            }
            .padding(.vertical, 8).padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.04) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(!e.isDir)
    }

    // MARK: Main

    private var mainArea: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 18).padding(.vertical, 12)
            Rectangle().fill(Brand.hairline).frame(height: 1)
            ZStack {
                if model.loading {
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large).tint(Tool.analyze.accent)
                        Text(L10n.scanning)
                            .font(Brand.sans(13, .medium)).foregroundStyle(Brand.textPrimary)
                        Text(L10n.analyzeLargeDirHint)
                            .font(Brand.mono(10)).foregroundStyle(Brand.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 300)
                } else if let err = model.error {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24)).foregroundStyle(Brand.orange)
                        Text(err)
                            .font(Brand.sans(12)).foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center).frame(maxWidth: 360)
                        Button { model.refresh() } label: {
                            Text(L10n.refresh).font(Brand.sans(12, .semibold)).foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Capsule().fill(Tool.analyze.accent))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    TreemapView(entries: model.entries) { e in model.drill(into: e) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            ForEach(Array(model.crumbs.enumerated()), id: \.offset) { idx, crumb in
                if idx > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Brand.textTertiary)
                }
                Button { model.goToCrumb(idx) } label: {
                    Text(crumb.name)
                        .font(Brand.sans(13, idx == model.crumbs.count - 1 ? .semibold : .regular))
                        .foregroundStyle(idx == model.crumbs.count - 1 ? Brand.textPrimary : Brand.textSecondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text(model.usageLine)
                .font(Brand.mono(10, .medium))
                .foregroundStyle(Brand.textTertiary)
            Button { model.refresh() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Brand.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Treemap rendering

struct TreemapView: View {
    let entries: [DiskScanEntry]
    let onOpen: (DiskScanEntry) -> Void
    @State private var hovered: String?
    @State private var pressed: String?

    // Modernized color palette with better harmony
    private static let palette: [Color] = [
        Color(hex: 0x5EC2FF), // Bright blue
        Color(hex: 0x4FD6C8), // Teal
        Color(hex: 0xFFB86C), // Warm orange
        Color(hex: 0xFF6B9D), // Pink
        Color(hex: 0xC5A3FF), // Purple
        Color(hex: 0x7ED6DF), // Cyan
        Color(hex: 0xFF8F5D), // Coral
        Color(hex: 0x6BCB77), // Green
        Color(hex: 0xA78BFA), // Light purple
        Color(hex: 0xF472B6), // Pink rose
        Color(hex: 0x34D399), // Emerald
        Color(hex: 0x60A5FA), // Royal blue
        Color(hex: 0xFBBF24), // Yellow
    ]

    var body: some View {
        GeometryReader { geo in
            let shown = Array(entries.filter { $0.size > 0 }.prefix(120))
            let rects = Treemap.layout(weights: shown.map { Double($0.size) },
                                       in: CGRect(x: 0, y: 0, width: geo.size.width, height: geo.size.height))
            ZStack(alignment: .topLeading) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, e in
                    block(e, rects[i], color: Self.palette[i % Self.palette.count], index: i)
                }
            }
        }
    }

    @ViewBuilder
    private func block(_ e: DiskScanEntry, _ r: CGRect, color: Color, index: Int) -> some View {
        let w = max(0, r.width - 2)
        let h = max(0, r.height - 2)
        let isHover = hovered == e.id
        let isPressed = pressed == e.id

        // Burrow-inspired opacity ranges
        let baseOpacity: Double = isHover ? 0.95 : (isPressed ? 0.85 : 0.80)
        let bottomOpacity: Double = isHover ? 0.70 : (isPressed ? 0.60 : 0.55)

        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(LinearGradient(
                colors: [color.opacity(baseOpacity), color.opacity(bottomOpacity)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        Color.black.opacity(0.25),
                        lineWidth: 1
                    )
            )
            .overlay(label(e, w: w, h: h))
            .frame(width: w, height: h)
            .offset(x: r.minX + 1, y: r.minY + 1)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isHover)
            .animation(.easeOut(duration: 0.08), value: isPressed)
            .onHover { hovering in
                hovered = hovering ? e.id : (hovered == e.id ? nil : hovered)
            }
            .onTapGesture { onOpen(e) }
            .contextMenu {
                Button(L10n.revealInFinder) { AnalyzeIcons.reveal(e.path) }
                if e.isDir { Button(L10n.openHere) { onOpen(e) } }
            }
    }

    @ViewBuilder
    private func label(_ e: DiskScanEntry, w: CGFloat, h: CGFloat) -> some View {
        if w > 70, h > 32 {
            VStack(spacing: 4) {
                if w > 100, h > 56 {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: e.isDir ? "folder.fill" : "doc.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                }
                Text(e.name)
                    .font(Brand.sans(12, .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.25), radius: 1)
                Text(Fmt.bytes(e.size))
                    .font(Brand.mono(9, .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .padding(8)
        }
    }
}

// MARK: - Icons / Finder helpers

enum AnalyzeIcons {
    private static var cache: [String: NSImage] = [:]

    static func icon(for e: DiskScanEntry) -> NSImage {
        if let c = cache[e.path] { return c }
        let img = NSWorkspace.shared.icon(forFile: e.path)
        cache[e.path] = img
        return img
    }

    static func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}

// MARK: - Model

@MainActor
final class AnalyzeModel: ObservableObject {
    @Published var entries: [DiskScanEntry] = []
    @Published var crumbs: [(name: String, path: String)] = []
    @Published var loading = false
    @Published var error: String?
    private var total: Int64 = 0
    private var started = false
    private let opId = UUID()

    // Public access for sidebar to compute size ratios
    var currentTotal: Int64 { total }

    var summaryLine: String {
        entries.isEmpty ? "—" : "\(L10n.itemsCount(entries.count)) · \(Fmt.bytes(total))"
    }
    var usageLine: String { "\(Fmt.bytes(total)) \(L10n.itemsIn) \(L10n.itemsCount(entries.count))" }

    func startIfNeeded() {
        guard !started else { return }
        started = true
        crumbs = []
        scan(NSHomeDirectory(), name: L10n.homeBreadcrumb, push: true)
    }

    func drill(into e: DiskScanEntry) {
        guard e.isDir else { return }
        scan(e.path, name: e.name, push: true)
    }

    func goToCrumb(_ idx: Int) {
        guard idx < crumbs.count else { return }
        let c = crumbs[idx]
        crumbs = Array(crumbs.prefix(idx + 1))
        scan(c.path, name: c.name, push: false)
    }

    func refresh() {
        guard let last = crumbs.last else { return }
        scan(last.path, name: last.name, push: false)
    }

    private func scan(_ path: String, name: String, push: Bool) {
        loading = true
        error = nil
        if push { crumbs.append((name, path)) }
        OperationCenter.shared.begin(opId, label: L10n.analyzingPath(name))
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let r = try DiskScanner.scan(path)
                let sum = r.totalSize > 0 ? r.totalSize : r.entries.reduce(0) { $0 + $1.size }
                Task { @MainActor in
                    self.entries = r.entries
                    self.total = sum
                    self.loading = false
                    OperationCenter.shared.end(self.opId, success: true, detail: L10n.analysisResult(r.entries.count, Fmt.bytes(sum)))
                }
            } catch {
                Task { @MainActor in
                    self.error = error.localizedDescription
                    self.loading = false
                    OperationCenter.shared.end(self.opId, success: false, detail: L10n.scanFailed)
                }
            }
        }
    }
}
