//  ProgressDashboardView.swift
//  CoachOS — Features/Progress
//
//  CALLOUT: Implements FR-6 (body metrics + progress photos) and design SS-3.
//  Weight is stored in base kg and displayed in the user's units. Uses Swift Charts
//  (iOS 16+) for the trend line. Includes the privacy reassurance the spec requires
//  near photo upload (visible only to client + coach).

import SwiftUI
import Charts

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var metrics: [MetricEntry] = []
    @Published var photos: [ProgressPhoto] = []
    @Published var loading = true
    private var api: APIService
    init(api: APIService) { self.api = api }
    func replaceAPI(_ api: APIService) { self.api = api }

    func load() async {
        loading = true
        metrics = (try? await api.fetchMetrics()) ?? []
        photos = (try? await api.fetchPhotos()) ?? []
        loading = false
    }
    // CALLOUT: Log a new weight; input arrives in display units and is converted to kg.
    func logWeight(displayValue: Double, pref: UnitPreference) async {
        let kg = Units.storeWeight(value: displayValue, from: pref)
        if let m = try? await api.logWeight(kg: kg, on: Date()) { metrics.append(m) }
    }
}

struct ProgressDashboardView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm = ProgressViewModel(api: MockAPIService())
    @State private var configured = false
    @State private var newWeight = ""

    var body: some View {
        Screen(title: "Progress") {
            if vm.loading {
                ProgressView().padding(.top, Space.xxl)
            } else if vm.metrics.isEmpty {
                // Encouraging empty state + first-log CTA (design SS-3).
                EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                               message: "Log your first weight to start seeing your trend.").frame(height: 320)
            } else {
                trendCard
            }

            // Weight logging
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeader(title: "Log weight (\(state.unitPref.weightLabel))")
                    HStack {
                        TextField("0.0", text: $newWeight).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        Button("Log") {
                            if let v = Double(newWeight) {
                                Task { await vm.logWeight(displayValue: v, pref: state.unitPref); newWeight = "" }
                            }
                        }.font(AppFont.button).foregroundColor(AppColor.accent)
                    }
                }
            }

            // Progress photos with privacy reassurance (§8)
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeader(title: "Progress photos")
                    Text("Visible only to you and your coach.").font(AppFont.caption).foregroundColor(AppColor.muted)
                    if vm.photos.isEmpty {
                        Text("No photos yet — add one to build your timeline.").font(AppFont.body).foregroundColor(AppColor.muted)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(vm.photos) { _ in
                                RoundedRectangle(cornerRadius: Radius.card).fill(AppColor.surface)
                                    .frame(width: 96, height: 128)
                                    .overlay(Image(systemName: "photo").foregroundColor(AppColor.muted))
                            } }
                        }
                    }
                }
            }
        }
        .task { if !configured { vm.replaceAPI(state.api); configured = true }; await vm.load() }
    }

    // CALLOUT: Trend chart. Maps base-kg series to display units on the fly.
    private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeader(title: "Weight trend")
                Chart(vm.metrics) { m in
                    LineMark(x: .value("Date", m.recordedOn),
                             y: .value("Weight", Units.displayWeight(kg: m.valueKg, in: state.unitPref)))
                        .foregroundStyle(AppColor.accent)
                    PointMark(x: .value("Date", m.recordedOn),
                              y: .value("Weight", Units.displayWeight(kg: m.valueKg, in: state.unitPref)))
                        .foregroundStyle(AppColor.accent)
                }
                .frame(height: 180)
                if let latest = vm.metrics.last {
                    Text("Latest: \(Units.weightString(kg: latest.valueKg, pref: state.unitPref))")
                        .font(AppFont.caption).foregroundColor(AppColor.muted)
                }
            }
        }
    }
}
