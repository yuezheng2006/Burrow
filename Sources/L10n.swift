//
//  L10n.swift
//  Burrow
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

    // MARK: - Common

    static var appName: String { "Burrow" }
    static var cancel: String { t("取消", en: "Cancel") }
    static var quit: String { t("退出", en: "Quit") }
    static var preview: String { t("预览", en: "Preview") }
    static var failedPrefix: String { t("失败：", en: "Failed: ") }
    static var openBurrow: String { t("打开 Burrow", en: "Open Burrow") }
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
        case .clean:    return t("给旧通道通通风。", en: "Fresh air through old tunnels.")
        case .apps:     return t("卸掉已经用不上的。", en: "Shed what you've outgrown.")
        case .optimize: return t("小调整，更顺畅。", en: "Small turns, a smoother run.")
        case .analyze:  return t("绘制每一层空间。", en: "Map every chamber below.")
        case .status:   return t("洞窟的每一次脉动。", en: "Every pulse of the den.")
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
        t("Burrow 会定时运行 `mo status --json`，首次数据将在一个采样周期内到达。",
          en: "Burrow runs `mo status --json` on a timer; the first row lands within a tick.")
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
    static var cleaningDontQuit: String { t("清理中，请勿退出。", en: "Cleaning… don't quit.") }
    static var previewReview: String { t("预览 — 确认后再正式清理。", en: "Preview — review, then clean for real.") }
    static var doneCachesCleared: String { t("完成 — 缓存已清除。", en: "Done — caches cleared.") }
    static var cleanCachesTitle: String { t("确认清理缓存？", en: "Clean caches for real?") }
    static var cleanCachesBody: String {
        t("Burrow 将以管理员权限运行 `mo clean`。缓存文件将被永久删除；Mole 的白名单与安全规则仍然生效。",
          en: "Burrow will run `mo clean` with administrator rights. Cache files are removed permanently; Mole's whitelist and safety rules still apply.")
    }
    static var clean: String { t("清理", en: "Clean") }
    static var scanningCaches: String { t("扫描缓存", en: "Scanning caches") }
    static var cleaningCaches: String { t("清理缓存", en: "Cleaning caches") }

    // MARK: - Optimize

    static var optimize: String { t("优化", en: "Optimize") }
    static var runAgain: String { t("再次运行", en: "Run again") }
    static var maintenanceComplete: String { t("维护完成", en: "Maintenance complete") }
    static func areasRefreshed(_ n: Int) -> String { fmt("已刷新 %d 个区域", en: "%d areas refreshed", n) }
    static var previewingMaintenance: String { t("预览维护任务…", en: "Previewing maintenance…") }
    static var runningMaintenance: String { t("正在运行维护…", en: "Running maintenance…") }
    static var previewComplete: String { t("预览完成。", en: "Preview complete.") }
    static var optimizing: String { t("优化中", en: "Optimizing") }
    static var optimizePreview: String { t("优化预览", en: "Optimize preview") }

    // MARK: - Analyze

    static var scanning: String { t("扫描中…", en: "Scanning…") }

    // MARK: - Software

    static var uninstall: String { t("卸载", en: "Uninstall") }
    static var updates: String { t("更新", en: "Updates") }
    static var searchApps: String { t("搜索应用", en: "Search apps") }
    static var readingApps: String { t("读取已安装应用…", en: "Reading installed apps…") }
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

    // MARK: - Settings

    static var languageLabel: String { t("语言", en: "Language") }
    static var languageChangeFootnote: String {
        t("语言变更后请重新打开主窗口以刷新界面。", en: "Reopen the main window after changing language.")
    }
    static var storage: String { t("存储", en: "Storage") }
    static var currentlyUsing: String { t("当前占用", en: "Currently using") }
    static var lastMaintenance: String { t("上次维护", en: "Last maintenance") }
    static var runMaintenanceNow: String { t("立即运行维护", en: "Run maintenance now") }
    static var storageFootnote: String {
        t("历史数据保存在 ~/Library/Application Support/Burrow/burrow.db。超出保留窗口的行将每小时清理。",
          en: "History lives at ~/Library/Application Support/Burrow/burrow.db. Rows past the retention window are pruned hourly.")
    }
    static var historyRetention: String { t("历史保留", en: "History retention") }
    static var keepHistoryFor: String { t("保留历史", en: "Keep history for") }
    static var vacuumAfterPrune: String { t("大量清理后压缩数据库", en: "Vacuum DB after large prunes") }
    static var sampling: String { t("采样", en: "Sampling") }
    static var sampleEvery: String { t("采样间隔", en: "Sample every") }
    static var samplingFootnote: String {
        t("Burrow 按此间隔运行 `mo status --json`。60 秒对图表已足够；更短间隔细节更细，但子进程开销更大。",
          en: "Burrow runs `mo status --json` at this cadence. 60 s is plenty for charts; tighter intervals give finer detail at the cost of more subprocess churn.")
    }
    static var mcpQueryServer: String { t("MCP 查询服务", en: "MCP query server") }
    static var enableMcpServer: String { t("启用 MCP 查询服务", en: "Enable MCP query server") }
    static var endpoint: String { t("端点", en: "Endpoint") }
    static var mcpFootnote: String {
        t("开关与端口变更需重启后生效。在 localhost 暴露 /health、/info、/snapshot、/metrics，以及 Claude Code 用的 `Burrow --mcp` stdio 服务。",
          en: "Toggle + port changes take effect after a relaunch. Exposes /health, /info, /snapshot, /metrics over localhost, plus the `Burrow --mcp` stdio server for Claude Code.")
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

    static var moleNotFoundTitle: String { t("未找到 Mole CLI", en: "Mole CLI not found") }
    static var moleNotFoundBody: String {
        t("""
        Burrow 依赖 Mole CLI（`mo`）获取系统指标与清理能力。请先安装：

            brew install mole

        然后重新启动 Burrow。
        """,
        en: """
        Burrow uses the Mole CLI (`mo`) for system metrics and cleanup. \
        Install it with:

            brew install mole

        Then relaunch Burrow.
        """)
    }
    static var dbOpenFailedTitle: String { t("无法打开 Burrow 历史数据库", en: "Couldn't open Burrow's history database") }
    static var appWillQuit: String { t("应用将退出。", en: "The app will quit.") }

    static var aboutBurrow: String { t("关于 Burrow", en: "About Burrow") }
    static var settingsMenu: String { t("设置…", en: "Settings…") }
    static var hideBurrow: String { t("隐藏 Burrow", en: "Hide Burrow") }
    static var quitBurrow: String { t("退出 Burrow", en: "Quit Burrow") }
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
}
