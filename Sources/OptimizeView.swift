//
//  OptimizeView.swift
//  Burrow
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

    var body: some View {
        if runner.phase == .idle {
            ToolHero(tool: .optimize, title: Tool.optimize.title, subtitle: Tool.optimize.tagline) {
                PillButton(title: L10n.optimize) { preview = false; runner.run(["optimize"], elevated: true, label: L10n.optimizing) }
                PillButton(title: L10n.preview, filled: false) { preview = true; runner.run(["optimize", "--dry-run"], label: L10n.optimizePreview) }
            }
        } else {
            let report = parseTaskReport(runner.lines)
            VStack(spacing: 0) {
                statusBar.padding(.horizontal, 18).padding(.top, 4).padding(.bottom, 12)
                Rectangle().fill(Brand.hairline).frame(height: 1)
                if isDone, !preview {
                    DoneBanner(accent: Tool.optimize.accent, title: L10n.maintenanceComplete,
                               detail: L10n.areasRefreshed(report.groups.count))
                }
                TaskReportView(groups: report.groups, accent: Tool.optimize.accent)
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if runner.phase == .running { ProgressView().controlSize(.small).tint(Tool.optimize.accent) }
            Text(statusText).font(Brand.mono(12)).foregroundStyle(Brand.textSecondary)
            Spacer()
            if isDone {
                Button { preview = false; runner.run(["optimize"], elevated: true, label: L10n.optimizing) } label: {
                    Label(L10n.runAgain, systemImage: "arrow.clockwise")
                        .font(Brand.mono(11)).foregroundStyle(Brand.textSecondary)
                }.buttonStyle(.plain)
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
}
