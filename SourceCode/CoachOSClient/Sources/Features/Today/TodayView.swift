//  TodayView.swift
//  CoachOS — Features/Today
//
//  CALLOUT: The signature screen (FR-5.1, design SS-1). Shows ONLY today: workout
//  (or rest), nutrition target, habits, due check-in — nothing else. Handles all
//  required states: loading, empty (no program), rest day, available, completed.

import SwiftUI

// CALLOUT: View model owns async loading + state so the View stays declarative.
@MainActor
final class TodayViewModel: ObservableObject {
    enum State { case loading, loaded(TodayBundle), empty, error(String) }
    @Published var state: State = .loading
    // CALLOUT: `var` (not let) so the first .task can swap the throwaway mock used
    // at @StateObject init for the single app-wide instance held in AppState. This
    // keeps state shared across tabs (completing a workout updates Today, etc.).
    private var api: APIService
    init(api: APIService) { self.api = api }
    func replaceAPI(_ api: APIService) { self.api = api }

    func load() async {
        state = .loading
        do {
            let bundle = try await api.fetchToday()
            // No workout log + no program → empty state (FR-5.1 acceptance).
            if bundle.workoutLog == nil { state = .empty } else { state = .loaded(bundle) }
        } catch { state = .error(error.localizedDescription) }
    }
}

struct TodayView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm: TodayViewModel
    @State private var didInit = false

    init() { _vm = StateObject(wrappedValue: TodayViewModel(api: MockAPIService())) }

    var body: some View {
        Screen(title: "Today") {
            switch vm.state {
            case .loading:
                ProgressView().padding(.top, Space.xxl)
            case .empty:
                // CALLOUT: Friendly empty state — guidance, not "No data" (§8 microcopy).
                EmptyStateView(icon: "calendar.badge.clock",
                               message: "Your coach is building your first program. Today's workout will appear here.")
                    .frame(height: 360)
            case .error(let m):
                EmptyStateView(icon: "exclamationmark.triangle", message: m,
                               ctaTitle: "Retry") { Task { await vm.load() } }
            case .loaded(let bundle):
                loaded(bundle)
            }
        }
        .task {
            // CALLOUT: Re-point the VM at the real app-wide API the first time we appear.
            if !didInit { vm.replaceAPI(state.api); didInit = true }
            await vm.load()
        }
    }

    @ViewBuilder
    private func loaded(_ b: TodayBundle) -> some View {
        // Workout card
        if let log = b.workoutLog {
            if log.isRest {
                Card { Label("Rest day — recover well 💤", systemImage: "moon.zzz.fill")
                        .font(AppFont.h3).foregroundColor(AppColor.ink) }
            } else if log.completedAt != nil {
                // Completed celebratory state (design SS-1).
                Card {
                    VStack(alignment: .leading, spacing: Space.s) {
                        StatusBadge(text: "Completed", kind: .success, systemImage: "checkmark.circle.fill")
                        Text(log.dayLabel).font(AppFont.h2).foregroundColor(AppColor.ink)
                        Text("Nice work — logged and synced to your coach.").font(AppFont.body).foregroundColor(AppColor.muted)
                    }
                }
            } else {
                NavigationLink(destination: WorkoutLoggingView(log: log)) {
                    Card {
                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Today's workout").font(AppFont.caption).foregroundColor(AppColor.muted)
                            Text(log.dayLabel).font(AppFont.h2).foregroundColor(AppColor.ink)
                            Text("\(log.setLogs.count) sets · \(Set(log.setLogs.map{$0.exerciseName}).count) exercises")
                                .font(AppFont.body).foregroundColor(AppColor.muted)
                            HStack { Spacer(); Text("Start").font(AppFont.button).foregroundColor(AppColor.accent) }
                        }
                    }
                }.buttonStyle(.plain)
            }
        }

        // Nutrition target (single coach-set value — MVP nutrition scope)
        if let target = b.nutritionTarget {
            Card { Label("Nutrition target: \(target)", systemImage: "fork.knife")
                    .font(AppFont.body).foregroundColor(AppColor.ink) }
        }

        // Habits checklist
        if !b.habits.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeader(title: "Habits")
                    ForEach(b.habits) { h in
                        HStack {
                            Image(systemName: h.done ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(h.done ? AppColor.success : AppColor.muted)
                            Text(h.text).font(AppFont.body).foregroundColor(AppColor.ink)
                        }
                    }
                }
            }
        }

        // Due check-in prompt
        if b.checkInDue {
            Card {
                HStack {
                    Label("Weekly check-in due", systemImage: "checkmark.seal")
                        .font(AppFont.body).foregroundColor(AppColor.warning)
                    Spacer()
                }
            }
        }
    }
}
