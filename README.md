# Fuchen (拂尘)

**Dust off your Mac — a free, open-source Clean My Mac alternative: native macOS GUI for the [Mole](https://github.com/tw93/Mole) CLI (`mo`).**

> 中文文档：[README.zh-CN.md](README.zh-CN.md)（界面默认简体中文，可在设置中切换 English）

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)
![Requires mole](https://img.shields.io/badge/requires-brew%20install%20mole-orange)

**Fuchen** (拂尘, “brush away the dust”) wraps the free, open-source `mo` CLI in a native Mac app: clean junk, manage & uninstall apps, run safe maintenance, map your disk, and watch live system status — five tools in one window.

On top of that it adds two things the CLI doesn't have: a **long-running history** of your Mac's metrics in a local SQLite database, and an **MCP server** so Claude Code can ask “what's been happening on this Mac.”

> Fuchen is an independent open-source project. It's *inspired by* mole.fit's structure and built on the same `mo` engine, but it is **not affiliated with or endorsed by mole.fit**.

## Screenshots

<table>
  <tr>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/1b0c402e-430c-4a15-ba90-195a050bf29a"></td>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/2b523363-cdc3-4a04-b858-67066fc95df4"></td>
  </tr>
  <tr>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/fda0b2e3-8bbd-42fe-b53c-12e18cdf5cf7"></td>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/0e59ba40-9bca-4483-8980-f03afcfad340"></td>
  </tr>
  <tr>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/5194a214-4d2c-4a6a-ad92-c22046e5005f"></td>
    <td><img alt="Fuchen" src="https://github.com/user-attachments/assets/40cc40cb-73ba-486a-ba15-356c032e6e04"></td>
  </tr>
</table>

<p align="center">
  <img width="320" alt="Menu-bar HUD" src="https://github.com/user-attachments/assets/515c2c8f-0332-4e8b-b880-2f2369ccb544">
</p>

## The five tools

| Tool | What it does | `mo` command |
|---|---|---|
| **Status** | Live dashboard — health score, CPU, memory, GPU, disk, network, battery with sparklines, plus a sortable process table. | `mo status --json` |
| **Analyze** | Squarified treemap of your disk; drill into any folder, reveal in Finder. | `mo analyze --json` |
| **Software** | Installed-app list with search/sort and multi-select uninstall; a Homebrew **Updates** tab. | `mo uninstall --list`, `brew outdated` |
| **Optimize** | One-click safe maintenance: rebuild caches, repair metadata, flush DNS, etc. | `mo optimize` |
| **Clean** | Preview reclaimable space, then run a categorized clean (caches, logs, leftovers). | `mo clean` |

### Fuchen extras

- **Menu-bar HUD** — health overview, metric cards, hot processes, in-app task status
- **History** — long-range charts (5 min to 90 days) in local SQLite, plus process peak tables
- **MCP server** — localhost HTTP API and stdio JSON-RPC (`Fuchen --mcp`) for Claude Code

## Language

- **Default UI: Simplified Chinese**
- Switch to **English** anytime in **Settings → Language** or the top-bar **中文 | EN** toggle
- Strings live in `Sources/L10n.swift`

## Requirements

- **macOS 14+**
- **Mole CLI** — `brew install mole` (hard requirement; Fuchen refuses to start without `mo`)

## Install

> Fuchen is **unsigned** for now (pre-1.0). Each path below clears Gatekeeper quarantine. See **[SECURITY.md](SECURITY.md)** for the honest trust model.

### Download (recommended)

Download `Fuchen-x.y.z.zip` or `.dmg` from
[Releases](https://github.com/yuezheng2006/fuchen/releases), move `Fuchen.app` to `/Applications`.

Before first launch: `xattr -cr /Applications/Fuchen.app` or right-click → Open.

### Homebrew cask (when tap is published)

```bash
brew install mole
brew install --cask yuezheng2006/tap/fuchen
```

### Build from source

```bash
brew install mole
git clone https://github.com/yuezheng2006/fuchen.git && cd fuchen
./scripts/release-swiftc.sh
./scripts/install-unsigned.sh
```

## Usage

Fuchen lives in the menu bar (menu-bar agent). Click the icon → **Open Fuchen**.

## MCP (Claude Code)

```json
{
  "mcpServers": {
    "fuchen": {
      "command": "/Applications/Fuchen.app/Contents/MacOS/Fuchen",
      "args": ["--mcp"]
    }
  }
}
```

Tools: `fuchen_snapshot`, `fuchen_history`, `fuchen_top_processes`, `fuchen_info`. HTTP API defaults to `127.0.0.1:9277`.

## Architecture

```
mo CLI ──> Fuchen GUI (SwiftUI + AppKit)
         ├─> SQLite history (~/Library/Application Support/Fuchen/fuchen.db)
         └─> Fuchen --mcp (stdio) ─> Claude Code
```

## License

MIT — Mole CLI © tw93. Independent project, not affiliated with mole.fit.
