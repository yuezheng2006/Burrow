//
//  SoftwareView.swift
//  Fuchen
//
//  The Software tab — lists installed apps with search/sort and uninstall.
//  Uses native directory scan for instant results; mole sizes refresh in
//  the background when available.
//

import SwiftUI
import AppKit

struct InstalledApp: Identifiable {
    let id: String
    let name: String
    let bundleId: String
    let source: String
    let uninstallName: String
    let path: String
    let sizeStr: String
    let sizeBytes: Int64
    let lastUsed: Date?
}

enum AppSort: String, CaseIterable { case size = "Size", name = "Name", recent = "Recent", source = "Source" }
enum SoftwareSegment { case uninstall, updates }

struct SoftwareView: View {
    @StateObject private var model = SoftwareModel()
    @StateObject private var updates = UpdatesModel()
    var isActive: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            toolbar.padding(.horizontal, 18).padding(.top, 4).padding(.bottom, 12)
            Rectangle().fill(Brand.hairline).frame(height: 1)
            content
            if model.segment == .uninstall {
                Rectangle().fill(Brand.hairline).frame(height: 1)
                bottomBar.padding(.horizontal, 18).padding(.vertical, 10)
            }
        }
        .onAppear { model.ensureLoaded() }
        .onChange(of: isActive) { _, now in if now { model.ensureLoaded() } }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            segmented
            Spacer()
            if model.segment == .uninstall {
                ForEach(AppSort.allCases, id: \.self) { s in
                    Button { model.setSort(s) } label: {
                        Text(L10n.sortLabel(s))
                            .font(Brand.mono(11, model.sort == s ? .semibold : .regular))
                            .foregroundStyle(model.sort == s ? Tool.apps.accent : Brand.textSecondary)
                    }.buttonStyle(.plain)
                }
                Button { model.refreshSizes() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(model.refreshing ? Tool.apps.accent : Brand.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.refreshSizes)
                .disabled(model.refreshing)
                searchField
            }
        }
    }

    private var segmented: some View {
        HStack(spacing: 2) {
            seg(L10n.uninstall, .uninstall)
            seg(L10n.updates, .updates)
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.22)))
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }

    private func seg(_ title: String, _ value: SoftwareSegment) -> some View {
        let on = model.segment == value
        return Button { model.segment = value } label: {
            Text(title).font(Brand.mono(11, on ? .semibold : .regular))
                .foregroundStyle(on ? Brand.textPrimary : Brand.textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background { if on { Capsule().fill(Brand.selectedChip) } }
                .contentShape(Capsule())
        }.buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass").font(.system(size: 10)).foregroundStyle(Brand.textTertiary)
            TextField(L10n.searchApps, text: $model.query)
                .textFieldStyle(.plain)
                .font(Brand.sans(12))
                .foregroundStyle(Brand.textPrimary)
                .frame(width: 130)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.22)))
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private var content: some View {
        if model.segment == .updates {
            UpdatesView(model: updates)
        } else if model.loading && model.apps.isEmpty {
            VStack { Spacer(); ProgressView(model.statusHint.isEmpty ? L10n.scanningApps : model.statusHint)
                .controlSize(.large).tint(Tool.apps.accent)
                .font(Brand.mono(11)); Spacer() }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.apps.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Text(model.error ?? L10n.noAppsFound).font(Brand.mono(12)).foregroundStyle(Brand.textSecondary)
                Button(L10n.refreshList) { model.reload() }.buttonStyle(.plain)
                    .font(Brand.sans(12, .semibold)).foregroundStyle(Tool.apps.accent)
                Spacer()
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                if model.refreshing || !model.statusHint.isEmpty {
                    HStack(spacing: 6) {
                        if model.refreshing {
                            ProgressView().controlSize(.small).tint(Tool.apps.accent)
                        }
                        Text(model.statusHint.isEmpty ? L10n.computingAppSizes : model.statusHint)
                            .font(Brand.mono(10)).foregroundStyle(Brand.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 18).padding(.vertical, 6)
                    Rectangle().fill(Brand.hairline).frame(height: 1)
                } else if model.needsSizeRefresh {
                    HStack(spacing: 6) {
                        Text(L10n.refreshSizesHint)
                            .font(Brand.mono(10)).foregroundStyle(Brand.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 18).padding(.vertical, 6)
                    Rectangle().fill(Brand.hairline).frame(height: 1)
                }
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.filtered) { app in
                            AppRow(app: app, selected: model.selected.contains(app.id)) {
                                model.toggle(app.id)
                            }
                            Rectangle().fill(Brand.hairline).frame(height: 1).padding(.leading, 58)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                }
                .scrollIndicators(.visible)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Text(model.selectionLabel).font(Brand.mono(11)).foregroundStyle(Brand.textSecondary)
            Spacer()
            Button {
                model.confirmAndUninstall()
            } label: {
                Text(L10n.uninstallCount(model.selected.count))
                    .font(Brand.sans(12, .semibold))
                    .foregroundStyle(model.selected.isEmpty ? Brand.textTertiary : .white)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(model.selected.isEmpty ? Color.white.opacity(0.06) : Tool.apps.accent))
            }
            .buttonStyle(.plain)
            .disabled(model.selected.isEmpty)
        }
    }
}

struct AppRow: View {
    let app: InstalledApp
    let selected: Bool
    let onToggle: () -> Void
    @State private var hover = false
    @State private var icon: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: icon ?? SoftwareIcons.placeholder)
                .resizable().frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name).font(Brand.sans(13, .medium)).foregroundStyle(Brand.textPrimary).lineLimit(1)
                Text("\(app.sizeStr) · \(app.source) · \(prettyPath)")
                    .font(Brand.mono(10)).foregroundStyle(Brand.textTertiary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 17))
                .foregroundStyle(selected ? Tool.apps.accent : Brand.textTertiary)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(hover ? Brand.cardFillHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture { onToggle() }
        .onAppear { loadIconIfNeeded() }
    }

    private func loadIconIfNeeded() {
        guard icon == nil else { return }
        let path = app.path
        DispatchQueue.global(qos: .utility).async {
            let img = NSWorkspace.shared.icon(forFile: path)
            DispatchQueue.main.async { icon = img }
        }
    }

    private var prettyPath: String {
        app.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}

enum SoftwareIcons {
    static let placeholder = NSWorkspace.shared.icon(forFileType: "app")

    private static var cache: [String: NSImage] = [:]
    static func icon(_ path: String) -> NSImage {
        if let c = cache[path] { return c }
        let img = NSWorkspace.shared.icon(forFile: path)
        cache[path] = img
        return img
    }
}

@MainActor
final class SoftwareModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var loading = false
    @Published var refreshing = false
    @Published var statusHint = ""
    @Published var error: String?
    @Published var query = ""
    @Published var sort: AppSort = .name
    @Published var selected: Set<String> = []
    @Published var segment: SoftwareSegment = .uninstall
    private var started = false
    private var refreshToken = UUID()

    var needsSizeRefresh: Bool {
        apps.contains { $0.sizeBytes == 0 }
    }

    var filtered: [InstalledApp] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let base = q.isEmpty ? apps : apps.filter { $0.name.lowercased().contains(q) }
        switch sort {
        case .size:   return base.sorted { $0.sizeBytes > $1.sizeBytes }
        case .name:   return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent: return base.sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .source: return base.sorted { $0.source < $1.source }
        }
    }

    var selectionLabel: String {
        if selected.isEmpty { return L10n.appCount(apps.count) }
        let total = apps.filter { selected.contains($0.id) }.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return L10n.selectedBytes(count: selected.count, bytes: Fmt.bytes(total))
    }

    func ensureLoaded() {
        if apps.isEmpty && !loading {
            load()
        } else if !started {
            started = true
            load()
        }
    }

    func reload() {
        refreshToken = UUID()
        refreshing = false
        statusHint = ""
        error = nil
        load(force: true)
    }

    func refreshSizes() {
        guard !refreshing, !apps.isEmpty else { return }
        let token = UUID()
        refreshToken = token
        refreshing = true
        let total = apps.count
        var done = 0
        var sizedCount = 0
        statusHint = L10n.sizeRefreshProgress(0, total)
        let snapshot = apps

        DispatchQueue.global(qos: .utility).async { [weak self] in
            AppSizeCalculator.sizeApps(snapshot, maxConcurrent: 12) { sized in
                DispatchQueue.main.async {
                    guard let self, self.refreshToken == token else { return }
                    if sized.sizeBytes > 0 { sizedCount += 1 }
                    if let idx = self.apps.firstIndex(where: { $0.path == sized.path }) {
                        self.apps[idx] = sized
                    }
                    done += 1
                    self.statusHint = L10n.sizeRefreshProgress(done, total)
                    if done >= total {
                        self.refreshing = false
                        if sizedCount < total {
                            self.statusHint = L10n.sizeRefreshSkipped
                        } else {
                            self.statusHint = ""
                        }
                        AppListCache.save(apps: self.apps)
                    }
                }
            }
        }
    }

    func setSort(_ s: AppSort) { sort = s }

    func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    func load(force: Bool = false) {
        started = true
        error = nil
        loading = apps.isEmpty
        statusHint = loading ? L10n.scanningApps : ""

        let cachedByPath = force ? [:] : Dictionary(
            uniqueKeysWithValues: AppListCache.loadApps().map { ($0.path, $0) }
        )

        // 1. 快速本地扫描（同步，不卡顿）
        let scanned = AppScanner.scan()

        guard !scanned.isEmpty else {
            apps = []
            loading = false
            statusHint = ""
            error = L10n.noAppsFound
            return
        }

        // 2. 先用缓存数据快速显示（避免卡顿）
        apps = scanned.map { app in
            if let cached = cachedByPath[app.path], cached.sizeBytes > 0 {
                return InstalledApp(
                    id: app.id,
                    name: app.name,
                    bundleId: app.bundleId,
                    source: cached.source.isEmpty ? app.source : cached.source,
                    uninstallName: cached.uninstallName.isEmpty ? app.uninstallName : cached.uninstallName,
                    path: app.path,
                    sizeStr: cached.sizeStr,
                    sizeBytes: cached.sizeBytes,
                    lastUsed: app.lastUsed)
            } else {
                return app
            }
        }
        loading = false

        // 3. 后台获取 mole 数据并更新
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let moleApps = self?.fetchMoleApps() ?? []
            let moleByPath = Dictionary(uniqueKeysWithValues: moleApps.map { ($0.path, $0) })

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // 合并 mole 数据
                self.apps = self.apps.map { app in
                    if let mole = moleByPath[app.path], mole.sizeBytes > 0 {
                        return InstalledApp(
                            id: app.id,
                            name: app.name,
                            bundleId: app.bundleId,
                            source: mole.source.isEmpty ? app.source : mole.source,
                            uninstallName: mole.uninstallName.isEmpty ? app.uninstallName : mole.uninstallName,
                            path: app.path,
                            sizeStr: mole.sizeStr,
                            sizeBytes: mole.sizeBytes,
                            lastUsed: app.lastUsed)
                    } else {
                        return app
                    }
                }
                AppListCache.save(apps: self.apps)
                // 只对仍无大小的应用触发 du
                self.refreshSizesIfNeeded()
            }
        }
    }

    /// 从 mole 获取应用列表（包含大小信息）
    private func fetchMoleApps() -> [InstalledApp] {
        do {
            let result = try MoleCLI.run(args: ["uninstall", "--list"], timeout: 30)
            guard result.exitCode == 0 else { return [] }
            guard let data = result.stdout.data(using: .utf8) else { return [] }
            let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            return AppListParser.parseMoleRows(arr ?? [])
        } catch {
            NSLog("SoftwareModel: failed to fetch mole apps: \(error.localizedDescription)")
            return []
        }
    }

    /// Fill cached sizes instantly; otherwise kick off a background refresh
    /// so the user doesn't have to click ↻ after every visit.
    /// Only sizes apps that don't have size data yet.
    private func refreshSizesIfNeeded() {
        let needsSizing = apps.filter { $0.sizeBytes == 0 }
        guard !needsSizing.isEmpty, !refreshing else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, !self.refreshing else { return }
            let stillNeeding = self.apps.filter { $0.sizeBytes == 0 }
            guard !stillNeeding.isEmpty else { return }
            self.refreshSizesPartial(stillNeeding)
        }
    }

    /// Size only the apps that don't have size data yet.
    private func refreshSizesPartial(_ needsSizing: [InstalledApp]) {
        guard !needsSizing.isEmpty else { return }
        let token = UUID()
        refreshToken = token
        refreshing = true
        let total = needsSizing.count
        var done = 0

        DispatchQueue.global(qos: .utility).async { [weak self] in
            AppSizeCalculator.sizeApps(needsSizing, maxConcurrent: 4) { sized in
                DispatchQueue.main.async {
                    guard let self, self.refreshToken == token else { return }
                    if let idx = self.apps.firstIndex(where: { $0.path == sized.path }) {
                        self.apps[idx] = sized
                    }
                    done += 1
                    self.statusHint = L10n.sizeRefreshProgress(done, total)
                    if done >= total {
                        self.refreshing = false
                        self.statusHint = ""
                        AppListCache.save(apps: self.apps)
                    }
                }
            }
        }
    }

    func confirmAndUninstall() {
        let targets = apps.filter { selected.contains($0.id) }
        guard !targets.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = L10n.uninstallAppsTitle(targets.count)
        alert.informativeText = L10n.trashRecoverable + "\n\n"
            + targets.map { "• \($0.name)" }.joined(separator: "\n")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.moveToTrash)
        alert.addButton(withTitle: L10n.cancel)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        refreshing = true
        statusHint = L10n.scanningApps
        let names = targets.map { $0.uninstallName }
        Task.detached(priority: .userInitiated) {
            _ = try? MoleCLI.run(args: ["uninstall"] + names, timeout: 300)
            let scanned = AppScanner.scan()
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.apps = scanned
                self.selected = []
                self.refreshing = false
                self.statusHint = ""
                AppListCache.save(apps: scanned)
            }
        }
    }
}
