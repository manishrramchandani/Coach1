//  AppState.swift
//  CoachOS — App
//
//  CALLOUT: App-wide state container injected via @EnvironmentObject. Holds the
//  chosen APIService (mock today, live tomorrow), the SyncEngine, and the session.
//  Centralizing this means features depend on protocols, not concrete services —
//  the dependency-injection seam SE.md recommends.

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var session: Session?           // nil = show onboarding
    let api: APIService
    let sync: SyncEngine

    init(api: APIService) {
        self.api = api
        self.sync = SyncEngine(api: api)
        // CALLOUT: Auto-resume — in the mock the user is pre-seeded so we land on
        // the main app. The live build would restore a Keychain session here.
        if let u = api.currentUser, let c = api.coach {
            self.session = Session(user: u, coach: c)
        }
    }

    var unitPref: UnitPreference { session?.user.unitPref ?? .metric }
}
