//
//  RootView.swift
//  Fuchen
//
//  The window shell: behind-window vibrancy → per-pane tint scrim → top
//  nav → pane content. One window, one navigation model — the five
//  tools plus Settings and History are all `Pane`s shown right here.
//

import SwiftUI

struct RootView: View {
    let db: DB
    let sampler: Sampler
    weak var delegate: AppDelegate?

    @ObservedObject private var languageStore = LanguageStore.shared
    @State private var pane: Pane
    @State private var mountedTools: Set<Tool>
    @State private var mountedSettings: Bool
    @State private var mountedHistory: Bool

    init(db: DB, sampler: Sampler, delegate: AppDelegate?, initialPane: Pane = .tool(.status)) {
        self.db = db
        self.sampler = sampler
        self.delegate = delegate
        self._pane = State(initialValue: initialPane)
        var tools: Set<Tool> = []
        var settings = false
        var history = false
        switch initialPane {
        case .tool(let t): tools.insert(t)
        case .settings: settings = true
        case .history: history = true
        }
        self._mountedTools = State(initialValue: tools)
        self._mountedSettings = State(initialValue: settings)
        self._mountedHistory = State(initialValue: history)
    }

    var body: some View {
        ZStack {
            VisualEffectBackground().ignoresSafeArea()
            pane.scrim.ignoresSafeArea()

            VStack(spacing: 0) {
                TopNav(selected: $pane)
                    .padding(.top, 13)
                    .padding(.bottom, 10)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 940, minHeight: 640)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.22), value: pane)
        .id(languageStore.current.rawValue) // Force refresh when language changes
        .onAppear { mount(pane) }
        .onChange(of: pane) { _, next in mount(next) }
        .onReceive(NotificationCenter.default.publisher(for: .fuchenNavigate)) { note in
            if let target = note.userInfo?["pane"] as? Pane {
                pane = target
            }
        }
    }

    /// Mount a pane the first time it is selected so we don't pay the cost
    /// of five tool views + CommandRunners at window open.
    private func mount(_ p: Pane) {
        switch p {
        case .tool(let t): mountedTools.insert(t)
        case .settings: mountedSettings = true
        case .history: mountedHistory = true
        }
    }

    private var content: some View {
        ZStack {
            if mountedTools.contains(.status) {
                StatusView(db: db, sampler: sampler).tabVisible(pane == .tool(.status))
            }
            if mountedTools.contains(.analyze) {
                AnalyzeView(isActive: pane == .tool(.analyze)).tabVisible(pane == .tool(.analyze))
            }
            if mountedTools.contains(.apps) {
                SoftwareView(isActive: pane == .tool(.apps)).tabVisible(pane == .tool(.apps))
            }
            if mountedTools.contains(.clean) {
                CleanView().tabVisible(pane == .tool(.clean))
            }
            if mountedTools.contains(.optimize) {
                OptimizeView().tabVisible(pane == .tool(.optimize))
            }

            if mountedSettings {
                SettingsView(onRunMaintenance: { [weak delegate] in delegate?.maintenance?.runNow() })
                    .tabVisible(pane == .settings)
            }
            if mountedHistory {
                HistoryView(db: db).tabVisible(pane == .history)
            }
        }
    }
}

private extension View {
    /// Keep a view in the hierarchy (so its @StateObject + work survive)
    /// while hiding it and disabling interaction when not the active pane.
    @ViewBuilder
    func tabVisible(_ visible: Bool) -> some View {
        self.opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
    }
}
