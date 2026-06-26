//  WorkoutLoggingView.swift
//  CoachOS — Features/Workout
//
//  CALLOUT: Implements FR-5.2 (log sets/reps/weights mid-workout) + design SS-2.
//  Large tap targets for the gym floor, per-set actual entry, a workout note, and
//  "Mark workout complete". Edits persist via SyncEngine so they survive app close
//  and offline use (last-write-wins sync when back online).

import SwiftUI

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published var log: WorkoutLog
    @Published var note: String = ""
    @Published var saving = false
    @Published var completed = false
    private var api: APIService
    private var sync: SyncEngine?

    init(log: WorkoutLog, api: APIService) { self.log = log; self.api = api; self.note = log.note ?? "" }
    func configure(api: APIService, sync: SyncEngine) { self.api = api; self.sync = sync }

    // CALLOUT: Update one set's actuals, mark dirty, persist locally + try to sync.
    func updateSet(_ id: UUID, reps: Int?, load: Double?, completed: Bool) {
        guard let i = log.setLogs.firstIndex(where: { $0.id == id }) else { return }
        log.setLogs[i].actualReps = reps
        log.setLogs[i].actualLoadKg = load
        log.setLogs[i].completed = completed
        log.dirty = true
        Task { await sync?.enqueue(log) }   // offline-safe persistence
    }

    var allComplete: Bool { log.setLogs.allSatisfy { $0.completed } }

    // CALLOUT: Finalize the workout → emits compliance event server-side (FR-5.2).
    func complete() async {
        saving = true
        do { try await api.completeWorkout(log.id, note: note.isEmpty ? nil : note); completed = true }
        catch { /* surfaced via state in a fuller build */ }
        saving = false
    }
}

struct WorkoutLoggingView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var sync: SyncEngine
    @StateObject private var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var configured = false

    init(log: WorkoutLog) { _vm = StateObject(wrappedValue: WorkoutViewModel(log: log, api: MockAPIService())) }

    // CALLOUT: Group flat SetLogs back into exercises, preserving the coach's
    // prescribed exercise order (first-appearance index in the original list).
    private var grouped: [(name: String, sets: [SetLog])] {
        var order: [String: Int] = [:]
        for (i, s) in vm.log.setLogs.enumerated() where order[s.exerciseName] == nil { order[s.exerciseName] = i }
        return Dictionary(grouping: vm.log.setLogs, by: { $0.exerciseName })
            .map { (name: $0.key, sets: $0.value.sorted { $0.setIndex < $1.setIndex }) }
            .sorted { (order[$0.name] ?? 0) < (order[$1.name] ?? 0) }
    }

    var body: some View {
        Screen(title: vm.log.dayLabel) {
            // Sync indicator (FR-5.2 "sync status shown per workout")
            if sync.pendingCount > 0 {
                StatusBadge(text: sync.isOnline ? "Syncing…" : "Saved offline",
                            kind: .warning, systemImage: "arrow.triangle.2.circlepath")
            }

            ForEach(grouped, id: \.name) { group in
                Card {
                    VStack(alignment: .leading, spacing: Space.m) {
                        Text(group.name).font(AppFont.h3).foregroundColor(AppColor.ink)
                        ForEach(group.sets) { set in SetRow(set: set, pref: state.unitPref) { reps, load, done in
                            vm.updateSet(set.id, reps: reps, load: load, completed: done)
                        } }
                    }
                }
            }

            // Workout note (visible to coach)
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeader(title: "Note for your coach")
                    TextField("e.g. shoulder felt tight", text: $vm.note, axis: .vertical)
                        .textFieldStyle(.roundedBorder).lineLimit(2...4)
                }
            }

            if vm.completed {
                StatusBadge(text: "Workout complete 🎉", kind: .success, systemImage: "checkmark.circle.fill")
            } else {
                PrimaryButton(title: "Mark workout complete", loading: vm.saving,
                              disabled: !vm.allComplete) { Task { await vm.complete(); dismiss() } }
            }
        }
        .task { if !configured { vm.configure(api: state.api, sync: sync); configured = true } }
    }
}

// CALLOUT: One logging row — prescribed values on the left, actual inputs on the
// right, a big completion toggle. Inputs respect the user's unit preference.
struct SetRow: View {
    let set: SetLog
    let pref: UnitPreference
    let onChange: (Int?, Double?, Bool) -> Void
    @State private var reps: String = ""
    @State private var load: String = ""
    @State private var done = false

    var body: some View {
        HStack(spacing: Space.s) {
            Text("Set \(set.setIndex)").font(AppFont.caption).foregroundColor(AppColor.muted).frame(width: 48, alignment: .leading)
            // Prescribed target (read-only)
            Text("\(set.prescribedReps) reps").font(AppFont.caption).foregroundColor(AppColor.muted).frame(width: 70, alignment: .leading)
            // Actual reps
            TextField("reps", text: $reps).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 56)
            // Actual load in display units
            TextField(pref.weightLabel, text: $load).keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(width: 64)
            Spacer()
            Button { done.toggle(); push() } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26)).foregroundColor(done ? AppColor.success : AppColor.muted)
            }.frame(width: 44, height: 44)   // 44pt tap target
        }
        .onAppear {
            if let r = set.actualReps { reps = String(r) }
            if let l = set.actualLoadKg { load = String(format: "%.0f", Units.displayWeight(kg: l, in: pref)) }
            done = set.completed
        }
    }
    // Convert entered load (display units) back to base kg before sending up.
    private func push() {
        let r = Int(reps)
        let l = Double(load).map { Units.storeWeight(value: $0, from: pref) }
        onChange(r, l, done)
    }
}
