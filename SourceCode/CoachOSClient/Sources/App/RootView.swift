//  RootView.swift
//  CoachOS — App
//
//  CALLOUT: Top-level router. Decides between onboarding (no session) and the main
//  tabbed app (active session), per the client happy path in MVP §2.2.

import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        Group {
            if state.session == nil {
                IntakeOnboardingView()      // FR-2.2 invite accept + intake
            } else {
                MainTabView()               // FR-5..9 client surfaces
            }
        }
    }
}
