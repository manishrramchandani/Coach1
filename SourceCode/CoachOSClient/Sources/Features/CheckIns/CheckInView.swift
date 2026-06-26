//  CheckInView.swift
//  CoachOS — Features/CheckIns
//
//  CALLOUT: Implements FR-7.1 (weekly check-in) + design SS-4. Collects weight,
//  1–5 ratings (energy/sleep/adherence), notes. The backend rejects a second
//  submission in the same ISO week; this screen surfaces that as a friendly state
//  and shows coach feedback once reviewed.

import SwiftUI

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var history: [CheckIn] = []
    @Published var submitting = false
    @Published var message: String?
    @Published var alreadyThisWeek = false
    private var api: APIService
    init(api: APIService) { self.api = api }
    func replaceAPI(_ api: APIService) { self.api = api }

    func load() async {
        history = (try? await api.fetchCheckIns()) ?? []
        // Disable the form if a check-in already exists for the current ISO week.
        let cal = Calendar(identifier: .iso8601)
        alreadyThisWeek = history.contains { cal.isDate($0.weekOf, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    func submit(weightKg: Double, ratings: Ratings, notes: String) async {
        submitting = true; message = nil
        do {
            let c = try await api.submitCheckIn(weightKg: weightKg, ratings: ratings, notes: notes)
            history.insert(c, at: 0); alreadyThisWeek = true; message = "Check-in sent to your coach."
        } catch { message = error.localizedDescription }   // e.g. duplicate-week error
        submitting = false
    }
}

struct CheckInView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm = CheckInViewModel(api: MockAPIService())
    @State private var configured = false
    @State private var weight = ""
    @State private var energy = 3, sleep = 3, adherence = 3
    @State private var notes = ""

    var body: some View {
        Screen(title: "Weekly check-in") {
            if vm.alreadyThisWeek {
                StatusBadge(text: "Submitted this week", kind: .success, systemImage: "checkmark.seal.fill")
            } else {
                form
            }
            if let m = vm.message { Text(m).font(AppFont.caption).foregroundColor(AppColor.muted) }

            // History with review status
            if !vm.history.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: Space.m) {
                        SectionHeader(title: "Past check-ins")
                        ForEach(vm.history) { c in
                            VStack(alignment: .leading, spacing: Space.xs) {
                                HStack {
                                    Text(Units.weightString(kg: c.weightKg, pref: state.unitPref))
                                        .font(AppFont.body).foregroundColor(AppColor.ink)
                                    Spacer()
                                    StatusBadge(text: c.status == .reviewed ? "Reviewed" : "Submitted",
                                                kind: c.status == .reviewed ? .success : .neutral,
                                                systemImage: c.status == .reviewed ? "checkmark.circle.fill" : "clock")
                                }
                                if let fb = c.coachFeedback { Text("Coach: \(fb)").font(AppFont.caption).foregroundColor(AppColor.muted) }
                            }
                            Divider()
                        }
                    }
                }
            }
        }
        .task { if !configured { vm.replaceAPI(state.api); configured = true }; await vm.load() }
    }

    private var form: some View {
        Card {
            VStack(alignment: .leading, spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Current weight (\(state.unitPref.weightLabel))").font(AppFont.caption).foregroundColor(AppColor.muted)
                    TextField("0.0", text: $weight).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                ratingRow("Energy", $energy)
                ratingRow("Sleep", $sleep)
                ratingRow("Adherence", $adherence)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Notes").font(AppFont.caption).foregroundColor(AppColor.muted)
                    TextField("How was your week?", text: $notes, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
                }
                PrimaryButton(title: "Send check-in", loading: vm.submitting, disabled: Double(weight) == nil) {
                    let kg = Units.storeWeight(value: Double(weight) ?? 0, from: state.unitPref)
                    Task { await vm.submit(weightKg: kg, ratings: Ratings(energy: energy, sleep: sleep, adherence: adherence), notes: notes) }
                }
            }
        }
    }

    // CALLOUT: 1–5 rating control (tap a number). Accessible label per value.
    private func ratingRow(_ title: String, _ value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title).font(AppFont.caption).foregroundColor(AppColor.muted)
            HStack {
                ForEach(1...5, id: \.self) { n in
                    Button { value.wrappedValue = n } label: {
                        Circle().fill(n <= value.wrappedValue ? AppColor.accent : AppColor.surface)
                            .overlay(Circle().stroke(AppColor.hairline))
                            .overlay(Text("\(n)").font(AppFont.caption).foregroundColor(n <= value.wrappedValue ? .white : AppColor.muted))
                            .frame(width: 40, height: 40)
                    }.accessibilityLabel("\(title) \(n)")
                }
            }
        }
    }
}
