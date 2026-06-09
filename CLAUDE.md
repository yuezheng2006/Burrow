# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fuchen** (拂尘, "brush away the dust") is a native macOS menu-bar app that provides a GUI for the [Mole CLI](https://github.com/tw93/Mole) (`mo` command). It monitors system health, manages disk space, and serves as an MCP server for Claude Code to query Mac metrics.

- **Language**: Swift (SwiftUI + AppKit)
- **Target**: macOS 14+
- **Hard dependency**: Mole CLI must be installed (`brew install mole`)
- **UI Languages**: Simplified Chinese (default), English (switchable in Settings)

## Build & Run

### Prerequisites
```bash
brew install mole        # Required — Fuchen won't launch without `mo`
brew install xcodegen    # Optional, for regenerating .xcodeproj
```

### Development build (Xcode)
```bash
xcodegen generate        # Regenerate Fuchen.xcodeproj from project.yml
open Fuchen.xcodeproj    # Build and run in Xcode (⌘R)
```

The `.xcodeproj` is gitignored; `project.yml` is the single source of truth. Re-run `xcodegen generate` after editing `project.yml`.

### Release build (swiftc)
```bash
./scripts/release-swiftc.sh    # Compiles, packages, creates .zip + .dmg in dist/
./scripts/install-unsigned.sh  # Installs to /Applications and clears quarantine
```

The release script builds a **universal binary** (arm64 + x86_64) via per-arch `swiftc` + `lipo`. Set `FUCHEN_ARCHS=arm64` for a faster Apple-Silicon-only local build. Set `CODESIGN_IDENTITY` and Apple notarization env vars to produce a signed/notarized build (see `docs/SIGNING.md`).

### Running tests
```bash
# In Xcode: ⌘U runs the FuchenTests target
# Or from CLI (requires xcodebuild):
xcodebuild test -project Fuchen.xcodeproj -scheme Fuchen -destination 'platform=macOS'
```

Tests live in `Tests/` and cover DB, MCP, localization, treemap algorithm, and Mole CLI integration.

## Architecture

### Core loop
```
┌─> Sampler (60s) ──> `mo status --json` ──> DB.insert(prefix: "mole.snapshot", json)
│                                               │
└─────────────────────────────────────────────┘
                                                │
                                                ├─> StatusView / HUD (read lastSnapshot in-memory)
                                                ├─> HistoryView (DB.findRangeSampled → charts)
                                                └─> MCP server (DB queries via fuchen_* tools)
```

**Sampler.swift** drives the loop: every N seconds (default 60, configurable in Settings), it spawns `mo status --json`, parses the result, and writes the raw JSON to the DB. The sampler keeps `lastSnapshot` in memory so the UI can redraw without DB reads.

**DB.swift** is a single SQLite table `samples(prefix, ts, json)` with WAL mode. The schema supports multiple prefixes (future: per-app metrics, custom probes) but today only `"mole.snapshot"` is used. The composite PK `(prefix, ts)` covers time-range queries; a separate `idx_ts` index supports cross-prefix TTL prunes (hourly maintenance deletes rows older than `Store.retentionDays`).

**MCP.swift** implements the Model Context Protocol stdio server. When launched with `--mcp`, Fuchen skips the GUI and runs a JSON-RPC 2.0 loop reading from stdin / writing to stdout. It opens a read-only SQLite handle into the same `fuchen.db` the GUI writes to — WAL mode allows concurrent reads. Four tools: `fuchen_snapshot` (latest), `fuchen_history` (time-series), `fuchen_top_processes` (peak aggregation), `fuchen_info` (DB metadata).

### Key components

- **MoleCLI.swift**: Subprocess wrapper for `mo`. Locates the executable via PATH + hardcoded Homebrew paths (GUI apps inherit a stripped PATH). All Fuchen commands route through `MoleCLI.run(args:)`.
- **Store.swift**: Typed UserDefaults access. Settings: `sampleIntervalSeconds` (5–3600), `retentionDays` (≥1), `language`, `queryServerPort`.
- **QueryServer.swift**: HTTP API on localhost:9277 (same endpoints as MCP, but over HTTP). Not used by the GUI; exists for external scripts.
- **StatusView.swift**: Live dashboard with health score, CPU/mem/disk/net sparklines, and a sortable process table.
- **HistoryView.swift**: Time-series charts (5 min to 90 days) via `DB.findRangeSampled`. Uses stride sampling (window functions) to cap result size at ~720 points regardless of query range.
- **AnalyzeView.swift**: Squarified treemap of disk usage via `mo analyze --json`. The `Treemap.swift` algorithm is tested in `TreemapTests.swift`.
- **SoftwareView.swift**: App list (`mo uninstall --list`) with multi-select uninstall, plus a **Updates** tab for Homebrew packages (`brew outdated`).
- **CleanView.swift** / **OptimizeView.swift**: Wrappers around `mo clean` / `mo optimize` with streaming output display.

### Localization

All user-facing strings live in **L10n.swift** as static properties. Each string is a computed property returning the appropriate value based on `Store.language`. The top-bar toggle and Settings sheet call `Store.language = .en` or `.zhHans`, which posts a `NotificationCenter` notification that triggers a full UI refresh.

```swift
// Adding a new string:
static var myNewString: String {
    switch LanguageStore.shared.current {
    case .zhHans: return "中文文本"
    case .en: return "English text"
    }
}
```

Don't use `NSLocalizedString` or `.xcstrings` — the L10n enum is the single source.

## MCP Integration (Claude Code)

Add this to your `~/.claude/settings.json`:

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

The MCP server exposes:
- `fuchen_snapshot` — latest system snapshot (CPU, mem, disk, net, thermal, top processes)
- `fuchen_history` — time-series slice (specify `minutes` and `samples`)
- `fuchen_top_processes` — peak CPU/mem aggregation over a window
- `fuchen_info` — DB metadata (row counts, staleness, retention settings)

Each tool returns JSON as a text payload. The server reads from the same SQLite DB the GUI writes to (concurrent reads via WAL).

## Common Tasks

### Add a new setting
1. Add a property to `Store.swift` with a default value and clamp logic
2. Add UI controls in `SettingsView.swift`
3. Read the setting in the relevant component (Sampler, QueryServer, etc.)

### Add a new view/tool tab
1. Add a case to `Tool` enum in `Tool.swift`
2. Create the view (e.g., `MyToolView.swift`) in `Sources/`
3. Wire it up in `RootView.swift`'s tab picker
4. Add localized strings to `L10n.swift`

### Debug Sampler not running
Check `Console.app` for logs prefixed `Fuchen.Sampler:`. Common issues:
- `mo` not found → MoleCLI can't locate the executable
- Exit code != 0 → Mole returned an error (stderr in logs)
- JSON decode failed → schema drift between Fuchen's `MoleStatus` struct and `mo`'s output

### Query the DB directly
```bash
sqlite3 ~/Library/Application\ Support/Fuchen/fuchen.db "SELECT prefix, datetime(ts, 'unixepoch', 'localtime'), length(json) FROM samples ORDER BY ts DESC LIMIT 10;"
```

The `json` column is the raw `mo status --json` output, stored as text.

## Code Conventions

- **No storyboards**: All UI is SwiftUI or programmatic AppKit (HUD, StatusBar)
- **Flat source tree**: All `.swift` files live directly in `Sources/`, except `Sources/Components/` for reusable UI pieces
- **Error handling**: Sampler/DB failures are logged to `NSLog` and swallowed (fail-open). MCP tool errors return JSON-RPC error responses.
- **Concurrency**: DB writes are serialized on a private queue; reads are concurrent (WAL). Sampler runs on a utility-priority queue. UI updates dispatch to `@MainActor`.
- **Comments**: Each file has a header comment explaining its purpose and how it fits into the architecture. Inline comments justify non-obvious decisions (e.g., why we use Mole's `collectedAt` timestamp instead of `Date()`).

## Testing MCP tools

```bash
# Stdio MCP (requires a JSON-RPC client or manual JSON)
/Applications/Fuchen.app/Contents/MacOS/Fuchen --mcp

# HTTP API (easier for ad-hoc queries)
curl http://127.0.0.1:9277/snapshot | jq .
curl http://127.0.0.1:9277/history?minutes=120 | jq .
```

The HTTP server (`QueryServer.swift`) uses the same `ToolCatalog` as the MCP server, so behavior is identical.
