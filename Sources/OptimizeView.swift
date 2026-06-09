//
//  OptimizeView.swift
//  Fuchen
//
//  The Optimize tab with enhanced UX: left panel shows friendly animations
//  and progress, right panel shows live technical logs.
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
            OptimizeProgressView(
                runner: runner,
                preview: preview,
                onRunAgain: { startOptimize() }
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                // 预览不需要授权
                runner.run(["optimize", "--dry-run"], elevated: false, label: L10n.optimizePreview)
                showStartAnimation = false
            }
        }
    }
}

/// Two-panel progress view for optimization
struct OptimizeProgressView: View {
    @ObservedObject var runner: CommandRunner
    let preview: Bool
    let onRunAgain: () -> Void

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

                // Stats card
                if isDone, !preview {
                    let groupCount = parseTaskReport(runner.lines).groups.count
                    statsCard(groupCount)
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

            LogScrollView(lines: runner.lines, accent: Tool.optimize.accent)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if runner.phase == .running {
                ProgressView().controlSize(.small).tint(Tool.optimize.accent)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(statusText).font(Brand.mono(11)).foregroundStyle(Brand.textSecondary)
                .animation(.easeInOut, value: statusText)
            Spacer()
            if isDone {
                Button(action: onRunAgain) {
                    Label(L10n.runAgain, systemImage: "arrow.clockwise")
                        .font(Brand.mono(10)).foregroundStyle(Brand.textSecondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var progressAnimation: some View {
        ZStack {
            if isRunning {
                OptimizingAnimation(accent: Tool.optimize.accent)
            } else if isDone {
                DoneAnimation(accent: Tool.optimize.accent)
            }
        }
        .frame(height: 160)
    }

    private func statsCard(_ count: Int) -> some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(Brand.mono(32, .bold))
                .foregroundStyle(Tool.optimize.accent)
            Text(L10n.areasRefreshed(count))
                .font(Brand.sans(13))
                .foregroundStyle(Brand.textSecondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Tool.optimize.accent.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Tool.optimize.accent.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 32)
    }

    private var isRunning: Bool { runner.phase == .running }
    private var isDone: Bool { if case .done = runner.phase { return true }; return false }

    private var statusText: String {
        switch runner.phase {
        case .running: return preview ? L10n.previewingMaintenance : L10n.runningMaintenance
        case .done:    return preview ? L10n.previewComplete : L10n.maintenanceComplete
        case .failed(let m): return L10n.failedPrefix + m
        case .idle:    return ""
        }
    }

    private var friendlyTitle: String {
        switch runner.phase {
        case .running: return preview ? L10n.previewingMaintenance : L10n.optimizingInProgress
        case .done:    return preview ? L10n.previewComplete : L10n.optimizeComplete
        case .failed:  return L10n.operationFailed
        case .idle:    return ""
        }
    }

    private var friendlySubtitle: String {
        switch runner.phase {
        case .running: return L10n.refreshingSystem
        case .done:    return L10n.systemTuned
        case .failed(let m):  return m
        case .idle:    return ""
        }
    }
}

/// Animated optimization icon during operation
struct OptimizingAnimation: View {
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

            Image(systemName: "bolt.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(accent)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}
