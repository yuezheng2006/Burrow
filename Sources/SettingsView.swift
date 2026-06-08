//
//  SettingsView.swift
//  Fuchen
//
//  Settings window (opened from the HUD's gear). Same contract as before
//  — reads/writes the typed `Store`, surfaces `Maintenance` status, and
//  notes which changes need a relaunch — but reskinned into the Brand
//  glass system to match the rest of the app. Hosted in a translucent
//  utility window by AppDelegate.
//

import SwiftUI

struct SettingsView: View {
    @State private var sampleIntervalSeconds: Int = Store.sampleIntervalSeconds
    @State private var retentionDays: Int = Store.retentionDays
    @State private var autoVacuum: Bool = Store.autoVacuum
    @State private var queryServerEnabled: Bool = Store.queryServerEnabled
    @State private var dbSizeText: String = "—"
    @State private var lastMaintenanceText: String = "—"

    /// Wired by AppDelegate; the only consumer is "Run maintenance now".
    var onRunMaintenance: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.settings).font(Brand.serif(24, .medium)).foregroundStyle(Brand.textPrimary)

                    section(L10n.languageLabel, "globe") {
                        LanguageToggle()
                        footnote(L10n.languageChangeFootnote)
                    }

                    section(L10n.storage, "internaldrive") {
                        infoRow(L10n.currentlyUsing, dbSizeText)
                        infoRow(L10n.lastMaintenance, lastMaintenanceText)
                        HStack {
                            Spacer()
                            PillButton(title: L10n.runMaintenanceNow, filled: false) {
                                onRunMaintenance?(); refreshStatusLabelsAsync()
                            }
                        }
                        footnote(L10n.storageFootnote)
                    }

                    section(L10n.historyRetention, "calendar") {
                        pickerRow(L10n.keepHistoryFor, selection: $retentionDays,
                                  options: [(1, L10n.retentionLabel(days: 1)), (7, L10n.retentionLabel(days: 7)),
                                            (14, L10n.retentionLabel(days: 14)), (30, L10n.retentionLabel(days: 30)),
                                            (90, L10n.retentionLabel(days: 90)), (180, L10n.retentionLabel(days: 180)),
                                            (365, L10n.retentionLabel(days: 365))]) {
                            Store.retentionDays = $0
                        }
                        toggleRow(L10n.vacuumAfterPrune, isOn: $autoVacuum) { Store.autoVacuum = $0 }
                    }

                    section(L10n.sampling, "waveform.path.ecg") {
                        pickerRow(L10n.sampleEvery, selection: $sampleIntervalSeconds,
                                  options: [(5, L10n.sampleIntervalLabel(seconds: 5)),
                                            (15, L10n.sampleIntervalLabel(seconds: 15)),
                                            (30, L10n.sampleIntervalLabel(seconds: 30)),
                                            (60, L10n.sampleIntervalLabel(seconds: 60)),
                                            (120, L10n.sampleIntervalLabel(seconds: 120)),
                                            (300, L10n.sampleIntervalLabel(seconds: 300))]) {
                            Store.sampleIntervalSeconds = $0
                        }
                        footnote(L10n.samplingFootnote)
                    }

                    section(L10n.mcpQueryServer, "antenna.radiowaves.left.and.right") {
                        toggleRow(L10n.enableMcpServer, isOn: $queryServerEnabled) { Store.queryServerEnabled = $0 }
                        infoRow(L10n.endpoint, "127.0.0.1:\(Store.queryServerPort)")
                        footnote(L10n.mcpFootnote)
                    }
                }
                .padding(22)
                .frame(maxWidth: 560, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { refreshStatusLabelsAsync() }
    }

    // MARK: - Section + row helpers

    private func section<C: View>(_ title: String, _ glyph: String, @ViewBuilder content: @escaping () -> C) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: title, glyph: glyph, color: Brand.textSecondary)
                content()
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Brand.sans(12)).foregroundStyle(Brand.textSecondary)
            Spacer()
            Text(value).font(Brand.mono(11)).foregroundStyle(Brand.textPrimary)
        }
    }

    private func footnote(_ text: String) -> some View {
        Text(text).font(Brand.mono(9)).foregroundStyle(Brand.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: isOn) {
            Text(label).font(Brand.sans(12)).foregroundStyle(Brand.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(Brand.green)
        .onChange(of: isOn.wrappedValue) { _, n in onChange(n) }
    }

    private func pickerRow(_ label: String, selection: Binding<Int>,
                           options: [(Int, String)], onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label).font(Brand.sans(12)).foregroundStyle(Brand.textPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { Text($0.1).tag($0.0) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Brand.textSecondary)
            .fixedSize()
            .onChange(of: selection.wrappedValue) { _, n in onChange(n) }
        }
    }

    // MARK: - Status labels

    private func refreshStatusLabelsAsync() {
        let maintenanceAt = AppDelegate.shared?.maintenance?.lastRunAt
        let pruned = AppDelegate.shared?.maintenance?.lastPruneDeleted ?? 0

        DispatchQueue.global(qos: .utility).async {
            let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                   in: .userDomainMask).first!
                .appendingPathComponent("Fuchen", isDirectory: true)
            var total: Int64 = 0
            if let enumerator = FileManager.default.enumerator(at: support,
                                                               includingPropertiesForKeys: [.fileSizeKey]) {
                for case let url as URL in enumerator {
                    if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                        total += Int64(size)
                    }
                }
            }
            let sizeText = Fmt.bytes(total)
            let maintenanceText: String
            if let last = maintenanceAt {
                let delta = Int(Date().timeIntervalSince(last))
                maintenanceText = L10n.maintenanceAgo(seconds: delta, pruned: pruned)
            } else {
                maintenanceText = L10n.notYetRun
            }
            DispatchQueue.main.async {
                self.dbSizeText = sizeText
                self.lastMaintenanceText = maintenanceText
            }
        }
    }

    private func refreshStatusLabels() {
        refreshStatusLabelsAsync()
    }
}
