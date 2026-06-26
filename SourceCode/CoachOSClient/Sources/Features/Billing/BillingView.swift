//  BillingView.swift
//  CoachOS — Features/Billing
//
//  CALLOUT: Implements the CLIENT side of FR-9 (subscribe / view status / cancel).
//  Hard rule: the app NEVER renders a card form — it opens Stripe's hosted flow via
//  SafariViewController-equivalent (here a Link). Subscription state is read from the
//  server (Stripe-webhook-driven); the client never assumes success locally.

import SwiftUI

@MainActor
final class BillingViewModel: ObservableObject {
    @Published var sub: Subscription?
    @Published var working = false
    private var api: APIService
    init(api: APIService) { self.api = api }
    func replaceAPI(_ api: APIService) { self.api = api }

    func load() async { sub = try? await api.fetchSubscription() }
    func checkoutURL() async -> URL? { try? await api.beginCheckoutURL() }
    func cancel() async {
        working = true
        sub = try? await api.cancelSubscription()   // access continues to period end
        working = false
    }
}

struct BillingView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var vm = BillingViewModel(api: MockAPIService())
    @State private var configured = false
    @State private var checkoutURL: URL?

    var body: some View {
        Screen(title: "Billing") {
            if let sub = vm.sub {
                Card {
                    VStack(alignment: .leading, spacing: Space.s) {
                        HStack {
                            Text("Subscription").font(AppFont.h3).foregroundColor(AppColor.ink)
                            Spacer()
                            statusBadge(sub.status)
                        }
                        Text(sub.displayPrice).font(AppFont.body).foregroundColor(AppColor.muted)
                        if let end = sub.currentPeriodEnd {
                            Text("\(sub.status == .canceled ? "Access until" : "Renews") \(end.formatted(date: .abbreviated, time: .omitted))")
                                .font(AppFont.caption).foregroundColor(AppColor.muted)
                        }
                    }
                }

                // CTA depends on state
                switch sub.status {
                case .active:
                    SecondaryButton(title: "Cancel subscription") { Task { await vm.cancel() } }
                case .pastDue, .none, .canceled:
                    PrimaryButton(title: "Subscribe", loading: vm.working) {
                        Task { checkoutURL = await vm.checkoutURL() }
                    }
                }

                if let url = checkoutURL {
                    // Opens Stripe-hosted checkout — never a custom card field (FR-9.2).
                    Link("Continue to secure checkout", destination: url)
                        .font(AppFont.button).foregroundColor(AppColor.accent)
                }
            } else {
                ProgressView().padding(.top, Space.xxl)
            }
        }
        .task { if !configured { vm.replaceAPI(state.api); configured = true }; await vm.load() }
    }

    private func statusBadge(_ s: SubscriptionStatus) -> StatusBadge {
        switch s {
        case .active:   return StatusBadge(text: "Active", kind: .success, systemImage: "checkmark.circle.fill")
        case .pastDue:  return StatusBadge(text: "Past due", kind: .warning, systemImage: "exclamationmark.triangle.fill")
        case .canceled: return StatusBadge(text: "Canceled", kind: .neutral, systemImage: "xmark.circle")
        case .none:     return StatusBadge(text: "Not subscribed", kind: .neutral, systemImage: "circle")
        }
    }
}
