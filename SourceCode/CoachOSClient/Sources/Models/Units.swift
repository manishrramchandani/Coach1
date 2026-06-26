//  Units.swift
//  CoachOS — Models
//
//  CALLOUT: Implements FR-6 unit handling. MVP §6/§4 require storing data in BASE
//  metric units (kg/cm) and converting only for DISPLAY, with exact, consistent
//  math. This isolates all conversion in one tested place so no screen does ad-hoc
//  math (a frequent bug source).

import Foundation

// CALLOUT: The user's preference, captured at intake (FR-2) and respected
// everywhere weight/height appear.
enum UnitPreference: String, Codable, CaseIterable, Identifiable {
    case metric    // kg / cm
    case imperial  // lb / in
    var id: String { rawValue }
    var weightLabel: String { self == .metric ? "kg" : "lb" }
    var heightLabel: String { self == .metric ? "cm" : "in" }
}

enum Units {
    // Exact factors (avoid rounding drift)
    static let kgPerLb = 0.45359237
    static let cmPerIn = 2.54

    // CALLOUT: storage(base kg) -> display value in the user's unit.
    static func displayWeight(kg: Double, in pref: UnitPreference) -> Double {
        pref == .metric ? kg : kg / kgPerLb
    }
    // CALLOUT: display value (user's unit) -> base kg for storage.
    static func storeWeight(value: Double, from pref: UnitPreference) -> Double {
        pref == .metric ? value : value * kgPerLb
    }
    static func displayHeight(cm: Double, in pref: UnitPreference) -> Double {
        pref == .metric ? cm : cm / cmPerIn
    }
    static func storeHeight(value: Double, from pref: UnitPreference) -> Double {
        pref == .metric ? value : value * cmPerIn
    }
    // CALLOUT: One formatter so "70.0 kg" / "154.3 lb" render identically app-wide.
    static func weightString(kg: Double, pref: UnitPreference) -> String {
        String(format: "%.1f %@", displayWeight(kg: kg, in: pref), pref.weightLabel)
    }
}
