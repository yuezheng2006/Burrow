//
//  Sampler.swift
//  Fuchen
//
//  Periodic sampler: spawns `mo status --json` on a background queue,
//  parses the JSON, writes the raw text to the DB under
//  `prefix: "mole.snapshot"`.
//
//  Cadence model: Fuchen doesn't run kernel sample loops itself (that's
//  Mole's job). The "energy gate" from Stats reduces here to a single
//  knob — `intervalSeconds` — defaulting to 60. At that rate, the
//  subprocess spawn cost is amortized to negligible; the popup-state
//  gate Stats needed for in-process readers doesn't apply.
//
//  Failure model: a single failed `mo status` invocation (timeout,
//  exec error, malformed JSON) is logged and retried at the next tick.
//  Repeated failure becomes visible through `/info`'s reader-staleness
//  surface — a Fuchen consumer sees `mole.snapshot` getting older just
//  the same way the Stats fork's stale-reader chip works.
//

import Foundation

final class Sampler {
    /// Bare-key prefix used by the QueryServer + chart code. One row per
    /// successful invocation, value = raw `mo status --json` payload.
    static let snapshotPrefix = "mole.snapshot"

    private let db: DB
    private let intervalSeconds: TimeInterval
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "dev.yuezheng2006.fuchen.sampler", qos: .utility)
    private let dec = JSONDecoder()

    /// Wall-clock time of the most recent successful sample. Exposed for
    /// the menu-bar status surface so we can show "12s ago" without
    /// hitting the DB.
    private(set) var lastSampleAt: Date?

    /// Last decoded snapshot — kept in memory so the popup can render the
    /// current values without a DB read on every redraw.
    private(set) var lastSnapshot: MoleStatus?

    init(db: DB, intervalSeconds: TimeInterval = 60) {
        self.db = db
        self.intervalSeconds = intervalSeconds
    }

    func start() {
        // Hydrate from DB so UI has data immediately; defer the first
        // `mo status` subprocess so launch stays responsive.
        self.queue.async {
            self.hydrateFromDB()
            self.scheduleNext(initialDelay: 3)
        }
    }

    /// Restore the last persisted snapshot so Status/HUD aren't empty
    /// while waiting for the first live `mo status` tick.
    private func hydrateFromDB() {
        guard let row = db.findLatest(prefix: Self.snapshotPrefix),
              let data = row.json.data(using: .utf8),
              let snapshot = try? dec.decode(MoleStatus.self, from: data) else { return }
        self.lastSnapshot = snapshot
        self.lastSampleAt = Date(timeIntervalSince1970: TimeInterval(row.ts))
    }

    func stop() {
        self.timer?.cancel()
        self.timer = nil
    }

    /// One-shot timer that re-arms after each tick. This is what lets
    /// the Sampler honor a Settings change at runtime without us
    /// teaching it to observe UserDefaults — we just re-pull the value
    /// at the moment we schedule the next fire.
    private func scheduleNext(initialDelay: TimeInterval? = nil) {
        let interval = TimeInterval(Store.sampleIntervalSeconds)
        let delay = initialDelay ?? interval
        let t = DispatchSource.makeTimerSource(queue: self.queue)
        t.schedule(deadline: .now() + delay, repeating: .never, leeway: .seconds(2))
        t.setEventHandler { [weak self] in
            self?.tick()
            self?.scheduleNext()
        }
        t.resume()
        self.timer = t
    }

    /// Single sample iteration. Synchronous from the caller's perspective —
    /// the timer queue is utility-priority so we don't block anything
    /// user-visible. Failures are swallowed and surfaced only through
    /// `lastSampleAt` not advancing.
    private func tick() {
        let result: MoleCLI.Result
        do {
            result = try MoleCLI.run(args: ["status", "--json"], timeout: 8)
        } catch {
            NSLog("Fuchen.Sampler: mo status failed to spawn: \(error.localizedDescription)")
            return
        }
        guard result.exitCode == 0 else {
            NSLog("Fuchen.Sampler: mo status exit=\(result.exitCode) stderr=\(result.stderr.prefix(200))")
            return
        }
        guard let data = result.stdout.data(using: .utf8) else { return }

        // Parse first — a malformed snapshot shouldn't pollute the DB.
        let snapshot: MoleStatus
        do {
            snapshot = try self.dec.decode(MoleStatus.self, from: data)
        } catch let DecodingError.keyNotFound(key, ctx) {
            // Surface the full coding path so a schema drift in `mo` shows
            // up as "missing key 'X' at path [a, b]" rather than the
            // useless "data couldn't be read" localized string.
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            NSLog("Fuchen.Sampler: missing key '\(key.stringValue)' at path '\(path)'")
            return
        } catch let DecodingError.typeMismatch(type, ctx) {
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            NSLog("Fuchen.Sampler: type mismatch (expected \(type)) at path '\(path)' — \(ctx.debugDescription)")
            return
        } catch let DecodingError.valueNotFound(type, ctx) {
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            NSLog("Fuchen.Sampler: nil value where \(type) expected at path '\(path)'")
            return
        } catch let DecodingError.dataCorrupted(ctx) {
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            NSLog("Fuchen.Sampler: data corrupted at path '\(path)' — \(ctx.debugDescription)")
            return
        } catch {
            NSLog("Fuchen.Sampler: JSON decode failed: \(error). First 200b: \(result.stdout.prefix(200))")
            return
        }

        // Use the timestamp Mole stamped on the snapshot rather than
        // Date() here. Two reasons: (1) if our tick lags by 200 ms, the
        // chart x-axis is still accurate; (2) Mole's `collected_at`
        // captures the sample window, not the JSON-emit time.
        let ts = Int(snapshot.collectedAt.timeIntervalSince1970)
        do {
            try self.db.insert(prefix: Sampler.snapshotPrefix, ts: ts, json: result.stdout)
        } catch {
            NSLog("Fuchen.Sampler: DB insert failed: \(error.localizedDescription)")
            return
        }

        self.lastSampleAt = Date()
        self.lastSnapshot = snapshot
    }
}
