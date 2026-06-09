//
//  CleanView.swift
//  Fuchen
//
//  The Clean tab with enhanced UX: left panel shows friendly animations
//  and progress, right panel shows live technical logs. Users see both
//  the friendly face and the technical detail.
//

import SwiftUI
import AppKit

struct CleanView: View {
    @StateObject private var runner = CommandRunner()
    @State private var mode: Mode = .dry
    @State private var showStartAnimation = false

    enum Mode { case dry, real }

    var body: some View {
        if runner.phase == .idle {
            ToolHero(tool: .clean, title: Tool.clean.title, subtitle: Tool.clean.tagline) {
                PillButton(title: L10n.cleanNow) { confirmReal() }
                    .scaleEffect(showStartAnimation ? 0.95 : 1.0)
                PillButton(title: L10n.preview, filled: false) { startDry() }
                    .scaleEffect(showStartAnimation ? 0.95 : 1.0)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            CleanProgressView(
                runner: runner,
                mode: mode,
                onRescan: { startDry() },
                onCleanForReal: { confirmReal() }
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func startDry() {
        withAnimation(.easeInOut(duration: 0.2)) { showStartAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                mode = .dry
                runner.run(["clean", "--dry-run"], label: L10n.scanningCaches)
                showStartAnimation = false
            }
        }
    }

    private func confirmReal() {
        let alert = NSAlert()
        alert.messageText = L10n.cleanCachesTitle
        alert.informativeText = L10n.cleanCachesBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.clean)
        alert.addButton(withTitle: L10n.cancel)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        withAnimation(.easeInOut(duration: 0.2)) { showStartAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                mode = .real
                runner.run(["clean"], elevated: true, label: L10n.cleaningCaches)
                showStartAnimation = false
            }
        }
    }
}

/// Two-panel progress view: left = friendly animation, right = technical log
struct CleanProgressView: View {
    @ObservedObject var runner: CommandRunner
    let mode: CleanView.Mode
    let onRescan: () -> Void
    let onCleanForReal: () -> Void

    var body: some View {
        HSplitView {
            // Left panel: friendly animation + summary
            leftPanel
                .frame(minWidth: 320, idealWidth: 400, maxWidth: 500)

            // Right panel: technical log
            rightPanel
                .frame(minWidth: 280, idealWidth: 350)
        }
    }

    private var leftPanel: some View {
        VStack(spacing: 0) {
            statusBar.padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 12)
            Rectangle().fill(Brand.hairline).frame(height: 1)

            VStack(spacing: 24) {
                Spacer()

                // Animated progress indicator
                progressAnimation

                // Friendly message
                VStack(spacing: 8) {
                    Text(friendlyTitle)
                        .font(Brand.serif(22, .medium))
                        .foregroundStyle(Brand.textPrimary)
                    Text(friendlySubtitle)
                        .font(Brand.sans(13))
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Summary stats
                if let summary = parseTaskReport(runner.lines).summary {
                    summaryCard(summary)
                }

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var rightPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Brand.textTertiary)
                Text(L10n.technicalLog)
                    .font(Brand.mono(10, .semibold))
                    .foregroundStyle(Brand.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.black.opacity(0.2))

            LogScrollView(lines: runner.lines, accent: Tool.clean.accent)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if isRunning {
                ProgressView().controlSize(.small).tint(Tool.clean.accent)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(statusText).font(Brand.mono(11)).foregroundStyle(Brand.textSecondary)
            Spacer()
            if isDone {
                Button(action: onRescan) {
                    Label(L10n.rescan, systemImage: "arrow.clockwise")
                        .font(Brand.mono(10)).foregroundStyle(Brand.textSecondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
            if mode == .dry, isDone {
                PillButton(title: L10n.cleanForReal, action: onCleanForReal)
            }
        }
    }

    @ViewBuilder
    private var progressAnimation: some View {
        ZStack {
            if isRunning {
                CleaningAnimation(accent: Tool.clean.accent)
            } else if isDone {
                DoneAnimation(accent: Tool.clean.accent)
            }
        }
        .frame(height: 160)
    }

    private func summaryCard(_ s: TaskSummary) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(s.space.isEmpty ? "—" : s.space)
                    .font(Brand.mono(32, .bold))
                    .foregroundStyle(Tool.clean.accent)
                Text(L10n.toFree)
                    .font(Brand.sans(14))
                    .foregroundStyle(Brand.textSecondary)
            }
            if !s.items.isEmpty {
                Text(L10n.itemsCategories(items: s.items, categories: s.categories))
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.textTertiary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Tool.clean.accent.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Tool.clean.accent.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 32)
    }

    private var isRunning: Bool { runner.phase == .running }
    private var isDone: Bool { if case .done = runner.phase { return true }; return false }

    private var statusText: String {
        switch runner.phase {
        case .running: return mode == .dry ? L10n.scanningMac : L10n.cleaningDontQuit
        case .done:    return mode == .dry ? L10n.previewReview : L10n.doneCachesCleared
        case .failed(let m): return L10n.failedPrefix + m
        case .idle:    return ""
        }
    }

    private var friendlyTitle: String {
        switch runner.phase {
        case .running: return mode == .dry ? L10n.scanningInProgress : L10n.cleaningInProgress
        case .done:    return mode == .dry ? L10n.scanComplete : L10n.cleanComplete
        case .failed:  return L10n.operationFailed
        case .idle:    return ""
        }
    }

    private var friendlySubtitle: String {
        switch runner.phase {
        case .running: return mode == .dry ? L10n.analyzingCaches : L10n.removingCaches
        case .done:    return mode == .dry ? L10n.reviewBeforeClean : L10n.macRefreshed
        case .failed(let m):  return m
        case .idle:    return ""
        }
    }
}

/// Animated cleaning icon during operation
struct CleaningAnimation: View {
    let accent: Color
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [accent.opacity(0.3), accent.opacity(0.05)],
                    center: .center,
                    startRadius: 10,
                    endRadius: 70
                ))
                .frame(width: 140, height: 140)
                .scaleEffect(scale)

            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accent)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}

/// Success checkmark animation
struct DoneAnimation: View {
    let accent: Color
    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkRotation: Double = -45
    @State private var circleScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(circleScale)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(accent)
                .scaleEffect(checkmarkScale)
                .rotationEffect(.degrees(checkmarkRotation))
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
                checkmarkRotation = 0
                circleScale = 1.0
            }
        }
    }
}

/// Scrollable log view with syntax highlighting
struct LogScrollView: View {
    let lines: [String]
    let accent: Color

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        LogLine(text: line, accent: accent)
                            .id(index)
                    }
                    Color.clear.frame(height: 1).id("BOTTOM")
                }
                .padding(12)
            }
            .background(Color.black.opacity(0.5))
            .scrollIndicators(.visible)
            .onChange(of: lines.count) { _, _ in
                withAnimation(.linear(duration: 0.1)) {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
            }
        }
    }
}

struct LogLine: View {
    let text: String
    let accent: Color

    var body: some View {
        Text(L10n.translateMoleString(text))
            .font(Brand.mono(10))
            .foregroundStyle(lineColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lineColor: Color {
        if text.contains("✓") || text.contains("✔") {
            return Brand.green
        } else if text.contains("→") || text.contains("➜") {
            return accent
        } else if text.contains("✗") || text.contains("error") {
            return Brand.red
        } else if text.starts(with: "➤") {
            return accent.opacity(0.9)
        } else {
            return Brand.textSecondary.opacity(0.8)
        }
    }
}
