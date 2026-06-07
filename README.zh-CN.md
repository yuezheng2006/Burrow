# Burrow

**免费开源的 [mole.fit](https://mole.fit/) 替代 — 原生 macOS GUI，封装 [Mole](https://github.com/tw93/Mole) CLI（`mo`）。**

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)
![Requires mole](https://img.shields.io/badge/requires-brew%20install%20mole-orange)
![中文](https://img.shields.io/badge/语言-简体中文-red)

> 英文文档见 [README.md](README.md)

Burrow 将免费开源的 `mo` CLI 包装成原生 Mac 应用：清理垃圾、管理/卸载应用、安全维护、磁盘可视化、实时系统监控 — 五大工具合于一窗。在此基础上还增加了 CLI 没有的两项能力：**长期历史**（本地 SQLite 记录 Mac 指标）和 **MCP 服务**（让 Claude Code 能问「这台 Mac 最近发生了什么」）。

> Burrow 是独立开源项目，受 mole.fit 的结构启发、基于同一 `mo` 引擎，但**与 mole.fit 无隶属或背书关系** — 名称、标识、配色与文案均为原创。

## 截图

<table>
  <tr>
    <td><img alt="Burrow" src="https://github.com/user-attachments/assets/1b0c402e-430c-4a15-ba90-195a050bf29a"></td>
    <td><img alt="Burrow" src="https://github.com/user-attachments/assets/2b523363-cdc3-4a04-b858-67066fc95df4"></td>
  </tr>
  <tr>
    <td><img alt="Burrow" src="https://github.com/user-attachments/assets/fda0b2e3-8bbd-42fe-b53c-12e18cdf5cf7"></td>
    <td><img alt="Burrow" src="https://github.com/user-attachments/assets/0e59ba40-9bca-4483-8980-f03afcfad340"></td>
  </tr>
</table>

## 五大工具

| 工具 | 功能 | `mo` 命令 |
|---|---|---|
| **清理** | 预览可释放空间，然后正式清理 — 分类清除缓存/日志/残留 | `mo clean` |
| **软件** | 已安装应用列表，支持搜索/排序/多选卸载；Homebrew **更新** 标签页 | `mo uninstall --list`, `brew outdated` |
| **优化** | 一键安全维护：重建缓存、修复元数据、刷新 DNS 等 | `mo optimize` |
| **分析** | 磁盘 squarified 树图；可钻入任意文件夹并在 Finder 中Reveal | `mo analyze --json` |
| **状态** | 实时仪表盘 — 健康分、CPU/内存/GPU/磁盘/网络/电池及 sparkline，可排序/置顶进程表 | `mo status --json` |

### Burrow 独有扩展

- **菜单栏 HUD** — 健康概览、指标卡片、热门进程、应用内任务状态
- **历史** — 5 分钟至 90 天的长期图表（本地 SQLite），以及进程峰值表
- **MCP 服务** — localhost HTTP API 与 stdio JSON-RPC（`Burrow --mcp`），供 Claude Code 查询 Mac 状态

## 语言

- **默认界面语言：简体中文**
- 可在 **设置 → 语言** 切换为 English
- 本地化通过 `L10n.swift` 集中管理，无旧版字符串键

## 系统要求

- **macOS 14+**
- **Mole CLI** — `brew install mole`（硬依赖，找不到 `mo` 则拒绝启动）

## 安装

> Burrow 目前**未签名**（pre-1.0）。各安装方式均会清除 Gatekeeper 隔离属性。安全说明见 **[SECURITY.md](SECURITY.md)**。

### 直接下载（推荐）

从 [Releases](https://github.com/yuezheng2006/Burrow/releases) 下载：

- **DMG** — `Burrow-x.y.z.dmg`：打开后把 Burrow 拖到「应用程序」文件夹
- **ZIP** — `Burrow-x.y.z.zip`：解压后把 `Burrow.app` 移到 `/Applications`

首次打开前执行（或右键 → 打开）：

```bash
xattr -cr /Applications/Burrow.app
```

### Homebrew

```bash
brew install mole
brew install --cask caezium/tap/burrow
```

### 源码编译

```bash
brew install xcodegen mole
git clone https://github.com/yuezheng2006/Burrow.git && cd Burrow
xcodegen generate
xcodebuild -project Burrow.xcodeproj -scheme Burrow \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
cp -R build/Build/Products/Release/Burrow.app /Applications/
xattr -cr /Applications/Burrow.app
open /Applications/Burrow.app
```

Burrow 驻留菜单栏（无 Dock 图标）。点击菜单栏图标 → **打开 Burrow**。

## 接入 Claude Code

在 `~/.claude/settings.json` 中添加：

```json
{
  "mcpServers": {
    "burrow": {
      "command": "/Applications/Burrow.app/Contents/MacOS/Burrow",
      "args": ["--mcp"]
    }
  }
}
```

工具：`burrow_snapshot`、`burrow_history`、`burrow_top_processes`、`burrow_info`。HTTP API 默认 `127.0.0.1:9277`。

## 开发与测试

```bash
xcodegen generate
xcodebuild -project Burrow.xcodeproj -scheme Burrow \
  -configuration Debug -destination 'platform=macOS' test
```

**47 项测试**：DB（10）、Store（11）、Maintenance（3）、MCP（7）、Treemap（9）、L10n（5）、Tool（4）。

## 架构

```
mo status --json   ──>  Sampler ──> SQLite (WAL) ──┬─> 状态 / 历史（图表）
                                                   ├─> HTTP QueryServer (:9277)
                                                   └─> Burrow --mcp (stdio) ─> Claude Code
mo analyze --json  ──>  DiskScanner + Treemap ──> 分析
mo clean / optimize ─>  CommandRunner ──> 清理 / 优化
mo uninstall --list ─>  软件（+ brew outdated 更新页）
```

## 许可与致谢

[MIT](LICENSE)

- **Mole CLI**（`mo`）© [tw93](https://github.com/tw93/Mole)，MIT
- 受 **mole.fit** Mac 应用启发，独立重实现，未使用其任何资产
- 树图布局：Bruls, Huijsen & van Wijk (2000) squarified treemap，Swift 从零实现
