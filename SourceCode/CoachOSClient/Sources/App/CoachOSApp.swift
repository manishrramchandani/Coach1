//  CoachOSApp.swift
//  CoachOS — App entry point
//
//  CALLOUT: The @main entry. Wires the dependency graph once (MockAPIService →
//  AppState) and applies the global Claude-white background + orange tint so every
//  screen inherits the theme. Swap MockAPIService for LiveAPIService to go live.

import SwiftUI

@main
struct CoachOSApp: App {
    // CALLOUT: One AppState for the whole app; @StateObject keeps it alive.
    @StateObject private var state = AppState(api: MockAPIService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(state.sync)
                .tint(AppColor.accent)                 // global orange accent
                .background(AppColor.background)
        }
    }
}
