//
//  L10n.swift
//  Fuchen
//
//  Lightweight bilingual UI strings. Default language is Simplified Chinese;
//  English is available from Settings. No legacy string keys — zh/en pairs only.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case en = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHans: return "简体中文"
        case .en:     return "English"
        }
    }
}

enum L10n {
    /// Pick zh or en based on the current Store language.
    static func t(_ zh: String, en: String) -> String {
        Store.language == .zhHans ? zh : en
    }

    static func fmt(_ zh: String, en: String, _ args: CVarArg...) -> String {
        String(format: t(zh, en: en), locale: Store.language == .zhHans ? Locale(identifier: "zh-Hans") : .current,
               arguments: args)
    }

    /// Translate common English strings from Mole CLI output to Chinese
    static func translateMoleString(_ text: String) -> String {
        guard Store.language == .zhHans else { return text }

        // Clean/Optimize output translations
        let translations: [String: String] = [
            // Clean task categories
            "SUMMARY": "概览",
            "SYSTEM": "系统",
            "USER ESSENTIALS": "用户数据",
            "BROWSER": "浏览器",
            "DEVELOPER": "开发工具",
            "APPLICATIONS": "应用程序",

            // Common messages
            "System-level cleanup enabled, sudo session active": "已启用系统级清理，管理员权限激活",
            "User-level cleanup will proceed automatically": "用户级清理将自动进行",
            "Whitelist": "白名单",
            "core patterns active": "个核心规则生效",

            // System items
            "System crash reports": "系统崩溃报告",
            "System logs": "系统日志",
            "Accessible rebuildable GPU caches": "可重建的 GPU 缓存",
            "System diagnostic logs": "系统诊断日志",
            "Power logs": "电源日志",
            "Nothing to clean": "无需清理",

            // User items
            "User app cache": "用户应用缓存",
            "User app logs": "用户应用日志",
            "items": "项",

            // General
            "Restart Recommended": "建议重启",
            "Good": "良好",
            "Excellent": "优秀",
            "Fair": "一般",
            "Poor": "较差",
            "Critical": "危险",
            "AC": "交流电",
            "Battery": "电池",
            "Charging": "充电中",
            "Discharging": "放电中",
            "Charged": "已充满",
            "normal": "正常",
            "warning": "警告",
            "critical": "严重"
        ]

        var result = text
        for (en, zh) in translations {
            result = result.replacingOccurrences(of: en, with: zh, options: .caseInsensitive)
        }
        return result
    }

    // MARK: - Common

    static var appName: String { t("拂尘", en: "Fuchen") }
    static var appTagline: String { t("为你的 Mac 拂去尘埃", en: "Whisk the dust from your Mac") }
    static var cancel: String { t("取消", en: "Cancel") }
    static var quit: String { t("退出", en: "Quit") }
    static var preview: String { t("预览", en: "Preview") }
    static var failedPrefix: String { t("失败：", en: "Failed: ") }
    static var openApp: String { t("打开拂尘", en: "Open Fuchen") }
    static var activity: String { t("活动", en: "Activity") }
    static var settings: String { t("设置", en: "Settings") }
    static var history: String { t("历史", en: "History") }

    // MARK: - Tools

    static func toolLabel(_ tool: Tool) -> String {
        switch tool {
        case .clean:    return t("清理", en: "clean")
        case .apps:     return t("软件", en: "apps")
        case .optimize: return t("优化", en: "optimize")
        case .analyze:  return t("分析", en: "analyze")
        case .status:   return t("状态", en: "status")
        }
    }

    static func toolTitle(_ tool: Tool) -> String {
        switch tool {
        case .clean:    return t("清理", en: "Clean")
        case .apps:     return t("软件", en: "Software")
        case .optimize: return t("优化", en: "Optimize")
        case .analyze:  return t("分析", en: "Analyze")
        case .status:   return t("状态", en: "Status")
        }
    }

    static func toolTagline(_ tool: Tool) -> String {
        switch tool {
        case .clean:    return t("扫尽积尘，焕然一新。", en: "Sweep the dust, breathe again.")
        case .apps:     return t("卸去无用，轻装前行。", en: "Shed what's weighing you down.")
        case .optimize: return t("轻拂系统，运转更顺。", en: "A gentle tune-up for smoother runs.")
        case .analyze:  return t("照见每一层空间。", en: "See where every byte lives.")
        case .status:   return t("静观机器的每一次呼吸。", en: "Every pulse of your Mac.")
        }
    }

    // MARK: - Health

    static func healthRating(_ score: Int) -> String {
        switch score {
        case 90...:   return t("优秀", en: "Excellent")
        case 75..<90: return t("良好", en: "Good")
        case 60..<75: return t("一般", en: "Fair")
        case 40..<60: return t("较差", en: "Poor")
        default:      return t("危险", en: "Critical")
        }
    }

    static var health: String { t("健康", en: "Health") }
    static var allChecksPassed: String { t("所有检查通过", en: "All checks passed") }
    static var waitingForSample: String { t("等待首次采样…", en: "Waiting for the first sample…") }
    static var waitingHint: String {
        t("拂尘会定时采集系统数据，首次数据将在一个采样周期内到达。",
          en: "Fuchen samples system data on a timer; the first data arrives within a tick.")
    }
    static var noSamplesYet: String { t("尚无采样", en: "no samples yet") }
    static func secondsAgo(_ s: Int) -> String { fmt("%d 秒前", en: "%ds ago", s) }

    // MARK: - Metrics

    static var cpu: String { "CPU" }
    static var memory: String { t("内存", en: "Memory") }
    static var gpu: String { "GPU" }
    static var network: String { t("网络", en: "Network") }
    static var disk: String { t("磁盘", en: "Disk") }
    static var battery: String { t("电池", en: "Battery") }
    static var power: String { t("电源", en: "Power") }
    static var acPower: String { t("交流电源", en: "AC Power") }
    static var gbFree: String { t("GB 可用", en: "GB free") }
    static var topProcesses: String { t("热门进程", en: "Top processes") }
    static func cores(_ n: Int) -> String { fmt("%d 核", en: "%d cores", n) }

    // Memory pressure labels
    static var memoryNormal: String { t("正常", en: "normal") }
    static var memoryWarning: String { t("警告", en: "warning") }
    static var memoryCritical: String { t("严重", en: "critical") }

    // CPU load format
    static func cpuLoadFormat(_ l1: Double, _ l5: Double, _ l15: Double) -> String {
        fmt("load %.2f · %.2f · %.2f", en: "load %.2f · %.2f · %.2f", l1, l5, l15)
    }

    // Memory format
    static func memoryFormat(_ used: Double, _ total: Double, _ swap: Double) -> String {
        fmt("%.1f / %.1f GB · 交换 %.1f GB", en: "%.1f / %.1f GB · swap %.1f GB", used, total, swap)
    }

    // GPU cores
    static var gpuCores: String { t("核", en: "cores") }

    // Network units and symbols
    static var kbPerSecond: String { t("KB/秒", en: "KB/s") }
    static var mbPerSecond: String { t("MB/秒", en: "MB/s") }
    static var downloadSymbol: String { "↓" }
    static var uploadSymbol: String { "↑" }

    // Rate formatting
    static func rateFormat(_ rx: Double, _ tx: Double, _ name: String, _ ip: String) -> String {
        fmt("%@ %.1f · %.1f MB/秒 · %@ · %@",
            en: "%@ %.1f · %.1f MB/s · %@ · %@",
            downloadSymbol, rx, tx, name, ip)
    }
    static func rateValue(_ mbs: Double) -> String {
        if mbs < 1 { return fmt("%d", en: "%d", Int(mbs * 1024)) + " " + kbPerSecond }
        return fmt("%.2f", en: "%.2f", mbs) + " " + mbPerSecond
    }

    // Disk format
    static func diskFormat(_ pct: Double, _ read: Double, _ write: Double) -> String {
        fmt("%.0f%% 已用 · R %.0f · W %.0f MB/秒", en: "%.0f%% used · R %.0f · W %.0f MB/s", pct, read, write)
    }

    // Battery status
    static var batteryGood: String { t("良好", en: "Good") }
    static var batteryCharging: String { t("充电中", en: "charging") }
    static var batteryTimeLeft: String { t("剩余", en: "left") }
    static var batteryCycles: String { t("次循环", en: "cyc") }
    static var batteryCapacity: String { t("容量", en: "cap") }

    // Uptime
    static var uptimePrefix: String { t("运行", en: "up") }
    static var uptimeSince: String { t("起", en: "since") }

    // Process table headers
    static var pidHeader: String { "PID" }
    static var memHeader: String { "MEM" }

    // Specs
    static func specsFormat(_ cpu: String, _ ram: String) -> String {
        return "\(cpu) · \(ram)"
    }

    // MARK: - Clean

    static var cleanNow: String { t("立即清理", en: "Clean Now") }
    static var rescan: String { t("重新扫描", en: "Re-scan") }
    static var cleanForReal: String { t("正式清理", en: "Clean for real") }
    static var toFree: String { t("可释放", en: "to free") }
    static var cleaned: String { t("清理完成", en: "Cleaned") }
    static func freedDetail(space: String, items: String) -> String {
        fmt("最多释放 %@ · %@ 项", en: "Freed up to %@ · %@ items", space, items)
    }
    static func itemsCategories(items: String, categories: String) -> String {
        fmt("· %@ 项 · %@ 类", en: "· %@ items · %@ categories", items, categories)
    }
    static var scanningMac: String { t("正在扫描 Mac…", en: "Scanning your Mac…") }
    static var cleaningDontQuit: String { t("清理中，让机器轻装上阵…", en: "Cleaning… lightening the load…") }
    static var previewReview: String { t("预览完成 — 确认后即可清理", en: "Preview complete — ready when you are") }
    static var doneCachesCleared: String { t("完成 — 您的 Mac 焕然一新", en: "Done — your Mac breathes easier now") }
    static var cleanCachesTitle: String { t("确认清理缓存？", en: "Clean caches for real?") }
    static var cleanCachesBody: String {
        t("拂尘将以管理员权限运行清理命令。缓存文件将被永久删除；安全规则仍然生效。",
          en: "Fuchen will run the clean command with administrator rights. Cache files are removed permanently; safety rules still apply.")
    }
    static var clean: String { t("清理", en: "Clean") }
    static var scanningCaches: String { t("扫描缓存", en: "Scanning caches") }
    static var cleaningCaches: String { t("清理缓存", en: "Cleaning caches") }

    // Progress messages
    static var technicalLog: String { t("技术日志", en: "Technical Log") }
    static var scanningInProgress: String { t("扫描进行中", en: "Scanning in Progress") }
    static var cleaningInProgress: String { t("清理进行中", en: "Cleaning in Progress") }
    static var scanComplete: String { t("扫描完成", en: "Scan Complete") }
    static var cleanComplete: String { t("清理完成", en: "Clean Complete") }
    static var operationFailed: String { t("操作失败", en: "Operation Failed") }
    static var analyzingCaches: String { t("正在分析缓存和日志文件", en: "Analyzing caches and log files") }
    static var removingCaches: String { t("正在移除不需要的文件", en: "Removing unnecessary files") }
    static var reviewBeforeClean: String { t("查看预览结果，确认后开始清理", en: "Review results and confirm to proceed") }
    static var macRefreshed: String { t("您的 Mac 已焕然一新", en: "Your Mac has been refreshed") }

    // MARK: - Optimize

    static var optimize: String { t("优化", en: "Optimize") }
    static var runAgain: String { t("再次运行", en: "Run again") }
    static var maintenanceComplete: String { t("维护完成", en: "Maintenance complete") }
    static func areasRefreshed(_ n: Int) -> String { fmt("已刷新 %d 个区域", en: "Refreshed %d areas", n) }
    static var previewingMaintenance: String { t("预览维护任务…", en: "Previewing maintenance…") }
    static var runningMaintenance: String { t("正在维护，让系统更顺畅…", en: "Tuning up… smoothing things out…") }
    static var previewComplete: String { t("预览完成 — 一切准备就绪", en: "Preview complete — ready to roll") }
    static var optimizing: String { t("优化中", en: "Optimizing") }
    static var optimizePreview: String { t("优化预览", en: "Optimize preview") }

    // Progress messages
    static var optimizingInProgress: String { t("优化进行中", en: "Optimizing in Progress") }
    static var optimizeComplete: String { t("优化完成", en: "Optimization Complete") }
    static var refreshingSystem: String { t("正在刷新系统组件", en: "Refreshing system components") }
    static var systemTuned: String { t("系统已调优完毕", en: "System has been tuned") }

    // MARK: - Analyze

    static var scanning: String { t("扫描中…", en: "Scanning…") }
    static var analyzeLargeDirHint: String {
        t("大型目录可能需要 10-30 秒", en: "Large directories may take 10-30 seconds")
    }
    static func itemsCount(_ n: Int) -> String { fmt("%d 项", en: "%d items", n) }
    static var itemsIn: String { t("于", en: "in") }
    static var homeBreadcrumb: String { t("主目录", en: "Home") }
    static func analyzingPath(_ path: String) -> String {
        fmt("正在分析 %@", en: "Analyzing %@", path)
    }
    static func analysisResult(_ count: Int, _ size: String) -> String {
        fmt("%@ 项 · %@", en: "%@ items · %@", "\(count)", size)
    }
    static var scanFailed: String { t("扫描失败", en: "scan failed") }
    static var revealInFinder: String { t("在访达中显示", en: "Reveal in Finder") }
    static var openHere: String { t("在此打开", en: "Open here") }

    // MARK: - Software

    static var uninstall: String { t("卸载", en: "Uninstall") }
    static var updates: String { t("更新", en: "Updates") }
    static var searchApps: String { t("搜索应用", en: "Search apps") }
    static var readingApps: String { t("读取已安装应用…", en: "Reading installed apps…") }
    static var scanningApps: String { t("正在扫描应用…", en: "Scanning applications…") }
    static var computingAppSizes: String { t("正在计算应用大小（可能需数分钟）…", en: "Computing app sizes (may take several minutes)…") }
    static var noAppsFound: String { t("未发现已安装应用", en: "No installed apps found") }
    static var sizeRefreshSkipped: String { t("部分应用大小未能读取（已跳过超时项）", en: "Some app sizes timed out and were skipped") }
    static func sizeRefreshProgress(_ done: Int, _ total: Int) -> String {
        fmt("正在计算应用大小 %d/%d…", en: "Computing app sizes %d/%d…", done, total)
    }
    static var refresh: String { t("刷新", en: "Refresh") }
    static var refreshSizes: String { t("刷新大小", en: "Refresh sizes") }
    static var refreshList: String { t("刷新列表", en: "Refresh list") }
    static var refreshSizesHint: String { t("点击 ↻ 计算应用大小（本地快速统计）", en: "Click ↻ to compute app sizes locally") }
    static func appCount(_ n: Int) -> String { fmt("%d 个应用", en: "%d apps", n) }
    static func selectedBytes(count: Int, bytes: String) -> String {
        fmt("已选 %d 个 · %@", en: "%d selected · %@", count, bytes)
    }
    static func uninstallCount(_ n: Int) -> String {
        n == 0 ? uninstall : fmt("卸载 (%d)", en: "Uninstall (%d)", n)
    }
    static func uninstallAppsTitle(_ n: Int) -> String {
        switch Store.language {
        case .zhHans: return fmt("卸载 %d 个应用？", en: "", n)
        case .en:     return n == 1 ? "Uninstall 1 app?" : "Uninstall \(n) apps?"
        }
    }
    static var moveToTrash: String { t("移到废纸篓", en: "Move to Trash") }
    static var trashRecoverable: String { t("这些应用将移到废纸篓（可恢复）：", en: "These move to the Trash (recoverable):") }

    static func sortLabel(_ sort: AppSort) -> String {
        switch sort {
        case .size:   return t("大小", en: "size")
        case .name:   return t("名称", en: "name")
        case .recent: return t("最近", en: "recent")
        case .source: return t("来源", en: "source")
        }
    }

    // MARK: - Updates

    static var checkingHomebrew: String { t("检查 Homebrew…", en: "Checking Homebrew…") }
    static var everythingUpToDate: String { t("全部已是最新", en: "Everything's up to date") }
    static var homebrewFormulaeCasks: String { t("Homebrew 公式与 Cask", en: "Homebrew formulae & casks") }
    static func updateCount(_ n: Int) -> String {
        switch Store.language {
        case .zhHans: return fmt("%d 个更新", en: "", n)
        case .en:     return n == 1 ? "1 update" : "\(n) updates"
        }
    }
    static var updateAll: String { t("全部更新", en: "Update all") }
    static var updating: String { t("更新中…", en: "Updating…") }
    static var update: String { t("更新", en: "Update") }
    static var brewNotFound: String {
        t("未在此 Mac 上找到 Homebrew（`brew`）。", en: "Homebrew (`brew`) not found on this Mac.")
    }

    // MARK: - History

    static var samples: String { t("条采样", en: "samples") }
    static func latestSecondsAgo(_ s: Int) -> String { fmt("· 最新 %d 秒前", en: "· latest %ds ago", s) }
    static var noSamplesInWindow: String { t("此时间窗口内无采样", en: "No samples in this window") }
    static var topProcessesPeak: String { t("窗口内峰值", en: "peak across window") }
    static var noProcessesRecorded: String { t("无进程记录", en: "No processes recorded") }
    static var cpuLoad: String { t("CPU 负载", en: "CPU load") }
    static var diskIO: String { t("磁盘 I/O", en: "Disk I/O") }
    static var thermal: String { t("温度", en: "Thermal") }
    static var healthScore: String { t("健康分", en: "Health score") }
    static var percentUsed: String { t("% 已用", en: "% used") }

    // Chart labels
    static var cpuUsage: String { t("CPU 使用率", en: "CPU usage") }
    static var oneMinAvg: String { t("1 分钟均值", en: "1m avg") }
    static var zeroToHundred: String { t("0–100", en: "0–100") }
    static var mbPerSecondShort: String { t("MB/秒", en: "MB/s") }

    // Process table
    static func peakCpuFormat(_ value: Double) -> String {
        fmt("%.1f%%", en: "%.1f%%", value)
    }
    static func peakMemFormat(_ value: Double) -> String {
        fmt("%.1f%%", en: "%.1f%%", value)
    }

    // MARK: - Settings

    static var languageLabel: String { t("语言", en: "Language") }
    static var languageChangeFootnote: String {
        t("切换后立即生效，无需重启。", en: "Applies immediately — no restart needed.")
    }
    static var storage: String { t("存储", en: "Storage") }
    static var currentlyUsing: String { t("当前占用", en: "Currently using") }
    static var lastMaintenance: String { t("上次维护", en: "Last maintenance") }
    static var runMaintenanceNow: String { t("立即运行维护", en: "Run maintenance now") }
    static var storageFootnote: String {
        t("历史数据保存在 ~/Library/Application Support/Fuchen/fuchen.db。超出保留窗口的行将每小时清理。",
          en: "History lives at ~/Library/Application Support/Fuchen/fuchen.db. Rows past the retention window are pruned hourly.")
    }
    static var historyRetention: String { t("历史保留", en: "History retention") }
    static var keepHistoryFor: String { t("保留历史", en: "Keep history for") }
    static var vacuumAfterPrune: String { t("大量清理后压缩数据库", en: "Vacuum DB after large prunes") }
    static var sampling: String { t("采样", en: "Sampling") }
    static var sampleEvery: String { t("采样间隔", en: "Sample every") }
    static var samplingFootnote: String {
        t("拂尘按此间隔采集系统数据。60 秒对图表已足够；更短间隔细节更细，但系统开销更大。",
          en: "Fuchen samples system data at this cadence. 60 s is plenty for charts; tighter intervals give finer detail at the cost of more system overhead.")
    }
    static var mcpQueryServer: String { t("MCP 查询服务", en: "MCP query server") }
    static var enableMcpServer: String { t("启用 MCP 查询服务", en: "Enable MCP query server") }
    static var endpoint: String { t("端点", en: "Endpoint") }
    static var mcpFootnote: String {
        t("开关与端口变更需重启后生效。在 localhost 暴露 /health、/info、/snapshot、/metrics，以及 Claude Code 用的 `Fuchen --mcp` stdio 服务。",
          en: "Toggle + port changes take effect after a relaunch. Exposes /health, /info, /snapshot, /metrics over localhost, plus the `Fuchen --mcp` stdio server for Claude Code.")
    }
    static var notYetRun: String { t("尚未运行", en: "not yet run") }
    static func maintenanceAgo(seconds: Int, pruned: Int) -> String {
        fmt("%d 秒前 · 清理 %d 行", en: "%ds ago · pruned %d rows", seconds, pruned)
    }

    static func retentionLabel(days: Int) -> String {
        switch days {
        case 1:   return t("1 天", en: "1 day")
        case 7:   return t("7 天", en: "7 days")
        case 14:  return t("14 天", en: "14 days")
        case 30:  return t("30 天", en: "30 days")
        case 90:  return t("90 天", en: "90 days")
        case 180: return t("180 天", en: "180 days")
        case 365: return t("1 年", en: "1 year")
        default:  return fmt("%d 天", en: "%d days", days)
        }
    }

    static func sampleIntervalLabel(seconds: Int) -> String {
        switch seconds {
        case 5:   return t("5 秒", en: "5 sec")
        case 15:  return t("15 秒", en: "15 sec")
        case 30:  return t("30 秒", en: "30 sec")
        case 60:  return t("60 秒", en: "60 sec")
        case 120: return t("2 分钟", en: "2 min")
        case 300: return t("5 分钟", en: "5 min")
        default:  return fmt("%d 秒", en: "%d sec", seconds)
        }
    }

    // MARK: - Alerts & menus

    static var moleNotFoundTitle: String { t("缺少必需组件", en: "Missing required component") }
    static var moleNotFoundBody: String {
        t("""
        拂尘需要安装系统支持组件才能运行。请在终端执行：

            brew install mole

        安装完成后重新启动拂尘。
        """,
        en: """
        Fuchen requires a system support component to run. Please install it with:

            brew install mole

        Then relaunch Fuchen.
        """)
    }
    static var dbOpenFailedTitle: String { t("无法打开拂尘历史数据库", en: "Couldn't open Fuchen's history database") }
    static var appWillQuit: String { t("应用将退出。", en: "The app will quit.") }

    static var aboutApp: String { t("关于拂尘", en: "About Fuchen") }
    static var settingsMenu: String { t("设置…", en: "Settings…") }
    static var hideApp: String { t("隐藏拂尘", en: "Hide Fuchen") }
    static var quitApp: String { t("退出拂尘", en: "Quit Fuchen") }
    static var editMenu: String { t("编辑", en: "Edit") }
    static var undo: String { t("撤销", en: "Undo") }
    static var redo: String { t("重做", en: "Redo") }
    static var cut: String { t("剪切", en: "Cut") }
    static var copy: String { t("拷贝", en: "Copy") }
    static var paste: String { t("粘贴", en: "Paste") }
    static var selectAll: String { t("全选", en: "Select All") }
    static var windowMenu: String { t("窗口", en: "Window") }
    static var minimize: String { t("最小化", en: "Minimize") }
    static var close: String { t("关闭", en: "Close") }

    // MARK: - Process table

    static func nameHeader(count: Int) -> String {
        fmt("名称 (%d)", en: "NAME (%d)", count)
    }

    // HUD / PopupView specific
    static var mcpEndpoint: String { t("MCP 端点", en: "MCP endpoint") }
    static var gpuLabel: String { "GPU" }

    // HUD format strings
    static func cpuLoadFoot(_ load: Double) -> String {
        fmt("load %.2f", en: "load %.2f", load)
    }
    static func memoryFoot(_ used: Double, _ total: Double) -> String {
        fmt("%.1f/%.0f GB", en: "%.1f/%.0f GB", used, total)
    }
    static func netFoot(_ rx: Int, _ tx: Int) -> String {
        fmt("%@ %d %@ %d KB/秒", en: "%@ %d %@ %d KB/s", downloadSymbol, rx, uploadSymbol, tx)
    }

    // Spec line in HUD
    static func specsLine(_ cpu: String, _ ram: String, _ uptime: String) -> String {
        return "\(cpu) · \(ram) · \(uptimePrefix) \(uptime)"
    }
}
