//  Theme.swift
//  CoachOS — Design System
//
//  CALLOUT: Single source of truth for the visual language. Per MVP.md §7 the
//  whole app must share ONE token set. The palette is the Claude theme the
//  product owner requested: WHITE surfaces, near-BLACK ink, ORANGE accent.
//  Every screen reads colors/space/type from here — never hard-coded hex.

import SwiftUI

// MARK: - Color tokens
// CALLOUT: Named, reusable color values (design tokens). Engineering and design
// reference the same names so the UI stays consistent and re-themable.
enum AppColor {
    // Brand — Claude white / black / orange
    static let background = Color(hex: 0xFFFFFF)   // App background (white)
    static let surface    = Color(hex: 0xFAF9F7)   // Cards / grouped rows (warm off-white)
    static let ink        = Color(hex: 0x141413)   // Primary text (near-black)
    static let accent     = Color(hex: 0xD97757)   // Claude orange — primary actions/accents
    static let accentDeep = Color(hex: 0xC15F3C)   // Pressed/active accent

    // Secondary text + lines
    static let muted      = Color(hex: 0x6B6B68)   // Secondary text, metadata, timestamps
    static let hairline   = Color(hex: 0xE7E4DF)   // Dividers, card borders

    // Semantic states (kept tonally close to brand so the UI stays calm — MVP.md §7)
    static let success    = Color(hex: 0x1B873F)   // Completion, streaks, positive trends
    static let warning    = Color(hex: 0xB45309)   // Overdue check-ins, past-due billing
    static let danger     = Color(hex: 0xB91C1C)   // Errors, destructive actions
}

// MARK: - Typography scale
// CALLOUT: Matches the type ramp in MVP design spec §7.2. 16pt minimum body for
// gym-floor readability. Uses the iOS system font (SF Pro) as agreed default.
enum AppFont {
    static let display = Font.system(size: 30, weight: .bold)      // Screen titles / big numbers
    static let h2      = Font.system(size: 22, weight: .semibold)  // Section headers
    static let h3      = Font.system(size: 18, weight: .semibold)  // Card titles
    static let body    = Font.system(size: 16, weight: .regular)   // Default text
    static let caption = Font.system(size: 13, weight: .regular)   // Metadata / helper text
    static let button  = Font.system(size: 16, weight: .semibold)  // Action labels
}

// MARK: - Spacing scale (4pt base)
// CALLOUT: Enforces the 4pt spacing system (§7.3). Using these constants instead
// of arbitrary numbers keeps rhythm consistent across screens.
enum Space {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Radius
enum Radius {
    static let card: CGFloat = 12   // Default card/input radius
    static let sheet: CGFloat = 16  // Large cards / sheets
    static let pill: CGFloat = 999  // Primary buttons
}

// MARK: - Hex initializer
// CALLOUT: Convenience to declare colors as 0xRRGGBB ints so tokens stay terse
// and unambiguous. Keeps the token file readable.
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
