//  MainTabView.swift
//  CoachOS — Features/Root
//
//  CALLOUT: The 5-tab bottom navigation from the client IA (MVP §3.2 / DEV §7.2).
//  Home is first and default — the product's signature "Today over everything".
//  Tab count is capped at 5 per the design spec.

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            NavigationStack { CheckInView() }
                .tabItem { Label("Check-in", systemImage: "checkmark.seal.fill") }
            NavigationStack { MessagesView() }
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }
            NavigationStack { AccountView() }
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .tint(AppColor.accent)   // selected tab = Claude orange
    }
}
