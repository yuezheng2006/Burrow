# 应用列表加载和大小计算改进方案

## 📊 当前实现分析

### 现有流程

```
SoftwareModel.load()
    ├─→ AppScanner.scan()  ← 扫描目录，无大小信息
    ├─→ AppListCache.load()  ← 从缓存读取历史大小
    └─→ refreshSizes()  ← 触发 du 计算
            └─→ AppSizeCalculator.sizeApps()
                    └─→ du -sk 每个应用（8秒超时）
```

### mole uninstall --list 输出

```json
[
  {
    "name": "Figma",
    "path": "/Applications/Figma.app",
    "size": "367.7MB",        ← 已有大小！
    "bundle_id": "com.figma.Desktop",
    "source": "Homebrew",
    "uninstall_name": "figma"
  },
  ...
]
```

## ⚡ 改进方案

### 方案 1: 优先使用 mole 数据（推荐）

```swift
// SoftwareModel.load() 改进
func load(force: Bool = false) {
    started = true
    error = nil
    loading = apps.isEmpty
    statusHint = loading ? L10n.scanningApps : ""

    // 1. 快速本地扫描
    let scanned = AppScanner.scan()

    // 2. 获取 mole 数据（包含大小）
    let moleApps = fetchMoleApps()  // 调用 mo uninstall --list

    // 3. 合并：以 mole 为主，扫描为辅
    let merged = AppListParser.merge(
        existing: scanned,        // 本地发现的应用
        fresh: moleApps           // mole 的数据（含大小）
    )

    apps = merged
    loading = false

    // 4. 仅对 mole 没有的应用进行 du 计算
    let needsSizing = apps.filter { $0.sizeBytes == 0 }
    if !needsSizing.isEmpty {
        refreshSizesPartial(needsSizing)
    }
}

private func fetchMoleApps() -> [InstalledApp] {
    do {
        let result = try MoleCLI.run(args: ["uninstall", "--list"], timeout: 30)
        guard result.exitCode == 0 else { return [] }
        guard let data = result.stdout.data(using: .utf8) else { return [] }
        let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        return AppListParser.parseMoleRows(arr ?? [])
    } catch {
        NSLog("Failed to fetch mole apps: \(error)")
        return []
    }
}
```

**优点**：
- ✅ 大部分应用从 mole 获取大小（单次调用，30秒超时）
- ✅ 只对 mole 没有的应用（如 System 应用）使用 du
- ✅ 大幅提升首次加载速度

**缺点**：
- ⚠️ mole 数据可能不是最新的
- ⚠️ 非 Homebrew 应用可能不在 mole 列表中

### 方案 2: 并行获取

```swift
func load(force: Bool = false) {
    // 同时执行本地扫描和 mole 查询
    DispatchQueue.global(qos: .userInitiated).async {
        let scanned = AppScanner.scan()
        let moleApps = self.fetchMoleApps()
        DispatchQueue.main.async {
            self.apps = AppListParser.merge(existing: scanned, fresh: moleApps)
            self.loading = false
        }
    }
}
```

## 📝 实现步骤

### 第一步：修改 SoftwareModel.load()

在 `Sources/SoftwareView.swift` 的 `SoftwareModel` 类中：

```swift
func load(force: Bool = false) {
    started = true
    error = nil
    loading = apps.isEmpty
    statusHint = loading ? L10n.scanningApps : ""

    let cachedByPath = force ? [:] : Dictionary(
        uniqueKeysWithValues: AppListCache.loadApps().map { ($0.path, $0) }
    )

    // 快速本地扫描
    let scanned = AppScanner.scan()
    loading = false
    statusHint = ""

    guard !scanned.isEmpty else {
        apps = []
        error = L10n.noAppsFound
        return
    }

    // 尝试从 mole 获取大小
    let moleApps = fetchMoleApps()

    // 合并：优先 mole 的大小，然后缓存，最后使用扫描结果
    var merged: [InstalledApp] = []
    for app in scanned {
        // 1. 检查 mole 是否有这个应用的大小
        if let mole = moleApps.first(where: { $0.path == app.path }), mole.sizeBytes > 0 {
            merged.append(InstalledApp(
                id: app.id,
                name: app.name,
                bundleId: app.bundleId,
                source: mole.source.isEmpty ? app.source : mole.source,
                uninstallName: mole.uninstallName.isEmpty ? app.uninstallName : mole.uninstallName,
                path: app.path,
                sizeStr: mole.sizeStr,
                sizeBytes: mole.sizeBytes,
                lastUsed: app.lastUsed
            ))
        }
        // 2. 检查缓存
        else if let cached = cachedByPath[app.path], cached.sizeBytes > 0 {
            merged.append(InstalledApp(
                id: app.id,
                name: app.name,
                bundleId: app.bundleId,
                source: cached.source.isEmpty ? app.source : cached.source,
                uninstallName: cached.uninstallName.isEmpty ? app.uninstallName : cached.uninstallName,
                path: app.path,
                sizeStr: cached.sizeStr,
                sizeBytes: cached.sizeBytes,
                lastUsed: app.lastUsed
            ))
        }
        // 3. 使用扫描结果（无大小）
        else {
            merged.append(app)
        }
    }

    apps = merged
    AppListCache.save(apps: apps)

    // 仅对仍无大小的应用触发 du
    if needsSizeRefresh {
        refreshSizesIfNeeded()
    }
}

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
```

### 第二步：优化 refreshSizes()

只对无大小的应用执行 du：

```swift
private func refreshSizesIfNeeded() {
    let needsSizing = apps.filter { $0.sizeBytes == 0 }
    guard !needsSizing.isEmpty, !refreshing else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.refreshSizesPartial(needsSizing)
    }
}

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
```

## 🎯 预期效果

### 改进前
```
首次加载: 扫描目录 (1秒) + du 每个应用 (每个 1-8秒)
         = 100 个应用 ≈ 100-800 秒
```

### 改进后
```
首次加载: 扫描目录 (1秒) + mole 查询 (5-10秒) + du 少数应用 (10-30秒)
         = 100 个应用 ≈ 15-40 秒  (提升 5-20 倍)
```

## 📚 相关文件

- `Sources/SoftwareView.swift` - UI 和加载逻辑
- `Sources/AppScanner.swift` - 本地目录扫描
- `Sources/AppSizeCalculator.swift` - du 大小计算
- `Sources/AppListCache.swift` - 缓存管理
- `Sources/AppListParser.swift` - mole 数据解析和合并
