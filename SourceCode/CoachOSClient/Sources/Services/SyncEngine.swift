//  SyncEngine.swift
//  CoachOS — Services
//
//  CALLOUT: Implements the sync contract from FR-5.2: offline edits are queued and
//  flushed when connectivity returns, with LAST-WRITE-WINS conflict resolution.
//  In the mock build this runs against MockAPIService; the strategy is identical
//  against the live API. Views show a per-workout sync indicator off `pendingCount`.

import Foundation
import Combine

@MainActor
final class SyncEngine: ObservableObject {
    @Published var pendingCount: Int = 0      // drives the "Saved locally — syncing…" UI
    @Published var isOnline: Bool = true       // toggled from Account screen to demo offline mode

    private let api: APIService
    init(api: APIService) { self.api = api }

    // CALLOUT: Persist locally FIRST (never lose data), then attempt to push. If
    // offline, the dirty flag stays set and the next flush() retries.
    func enqueue(_ log: WorkoutLog) async {
        var stored = LocalStore.shared.load([WorkoutLog].self, key: "pending_logs") ?? []
        stored.removeAll { $0.id == log.id }
        stored.append(log)
        LocalStore.shared.save(stored, key: "pending_logs")
        pendingCount = stored.filter { $0.dirty }.count
        await flush()
    }

    // CALLOUT: Flush queue when online. Last-write-wins: we send our version; the
    // server's idempotent upsert accepts the latest timestamp.
    func flush() async {
        guard isOnline else { return }
        var stored = LocalStore.shared.load([WorkoutLog].self, key: "pending_logs") ?? []
        for i in stored.indices where stored[i].dirty {
            do { try await api.saveWorkoutLog(stored[i]); stored[i].dirty = false }
            catch { /* stays dirty, retried next flush */ }
        }
        LocalStore.shared.save(stored, key: "pending_logs")
        pendingCount = stored.filter { $0.dirty }.count
    }
}
