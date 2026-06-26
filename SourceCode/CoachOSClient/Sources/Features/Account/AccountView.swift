//  AccountView.swift
//  CoachOS — Features/Account
//
//  CALLOUT: Profile + billing entry + an OFFLINE toggle used to demo the offline-
//  first behavior (FR-5.2 / NFR). Also exposes data export/delete entry points the
//  privacy NFR requires (GDPR-style) — wired to the API in the live build.

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var sync: SyncEngine

    var body: some View {
        Screen(title: "Account") {
            if let user = state.session?.user {
                Card {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text(user.name).font(AppFont.h2).foregroundColor(AppColor.ink)
                        Text(user.email).font(AppFont.body).foregroundColor(AppColor.muted)
                        Text("Units: \(user.unitPref == .metric ? "Metric" : "Imperial")")
                            .font(AppFont.caption).foregroundColor(AppColor.muted)
                    }
                }
            }
            if let coach = state.session?.coach {
                Card { Label("Your coach: \(coach.name)", systemImage: "figure.run").foregroundColor(AppColor.ink) }
            }

            NavigationLink(destination: BillingView()) {
                Card { Label("Billing & subscription", systemImage: "creditcard").foregroundColor(AppColor.ink) }
            }.buttonStyle(.plain)

            // CALLOUT: Offline simulator — flip to prove logs persist and sync later.
            Card {
                Toggle(isOn: Binding(get: { !sync.isOnline }, set: { sync.isOnline = !$0; if !$0 { Task { await sync.flush() } } })) {
                    Label("Offline mode (demo)", systemImage: "wifi.slash").foregroundColor(AppColor.ink)
                }.tint(AppColor.accent)
            }

            // Privacy controls (NFR: data export/delete)
            Card {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeader(title: "Privacy")
                    Button("Export my data") {}.foregroundColor(AppColor.accent)
                    Button("Delete my account") {}.foregroundColor(AppColor.danger)
                }
            }
        }
    }
}
