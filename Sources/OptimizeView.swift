//
//  OptimizeView.swift
//  Fuchen
//
//  The Optimize tab — mole.fit's "Mercury" one-tap maintenance, our
//  brand. "Optimize" runs the safe maintenance tasks (elevated through a
//  single auth prompt so there aren't repeated password dialogs);
//  "Preview" is a no-auth `--dry-run`. Results render through the shared
//  TaskReportView and finish on a done banner.
//

import SwiftUI

struct OptimizeView: View {
    @StateObject private var runner = CommandRunner()
    @State private var preview = false
    @State private var showStartAnimation = false

    var body: some View {
        if runner.phase == .idle {
            ToolHero(tool: .optimize, title: Tool.optimize.title, subtitle: Tool.optimize.tagline) {
                PillButton(title: L10n.optimize) { startOptimize() }
                    .scaleEffect(showStartAnimation ? 0.95 : 1.0)
                PillButton(title: L10n.preview, filled: false) { startPreview() }
                    .scaleEffect(showStartAnimation ? 0.95 : 1.0)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            let report = parseTaskReport(runner.lines)
            VStack(spacing: 0) {
                statusBar.padding(.horizontal, 18).padding(.top, 4).padding(.bottom, 12)
                Rectangle().fill(Brand.hairline).frame(height: 1)
                if isDone, !preview {
                    DoneBanner(accent: Tool.optimize.accent, title: L10n.maintenanceComplete,
                               detail: L10n.areasRefreshed(report.groups.count))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                TaskReportView(groups: report.groups, accent: Tool.optimize.accent, isRunning: runner.phase == .running)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if runner.phase == .running {
                ProgressView().controlSize(.small).tint(Tool.optimize.accent)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(statusText).font(Brand.mono(12)).foregroundStyle(Brand.textSecondary)
                .animation(.easeInOut, value: statusText)
            Spacer()
            if isDone {
                Button { startOptimize() } label: {
                    Label(L10n.runAgain, systemImage: "arrow.clockwise")
                        .font(Brand.mono(11)).foregroundStyle(Brand.textSecondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var isDone: Bool { if case .done = runner.phase { return true }; return false }

    private var statusText: String {
        switch runner.phase {
        case .running: return preview ? L10n.previewingMaintenance : L10n.runningMaintenance
        case .done:    return preview ? L10n.previewComplete : L10n.maintenanceComplete
        case .failed(let m): return L10n.failedPrefix + m
        case .idle:    return ""
        }
    }

    private func startOptimize() {
        withAnimation(.easeInOut(duration: 0.2)) { showStartAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                preview = false
                runner.run(["optimize"], elevated: true, label: L10n.optimizing)
                showStartAnimation = false
            }
        }
    }

    private func startPreview() {
        withAnimation(.easeInOut(duration: 0.2)) { showStartAnimation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                preview = true
                runner.run(["optimize", "--dry-run"], label: L10n.optimizePreview)
                showStartAnimation = false
            }
        }
    }
}
