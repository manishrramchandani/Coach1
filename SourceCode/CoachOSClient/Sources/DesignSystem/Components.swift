//  Components.swift
//  CoachOS — Design System
//
//  CALLOUT: Reusable UI components built ONCE with all required states
//  (default/pressed/disabled/loading/empty) per MVP design spec §7.4. Features
//  compose these instead of styling one-offs, guaranteeing a consistent look and
//  WCAG-AA touch targets (44pt).

import SwiftUI

// MARK: - Primary button
// CALLOUT: The single primary call-to-action style. Orange fill, pill shape,
// 44pt min height, shows a spinner while `loading` and is non-tappable when
// disabled or loading (prevents double submits — important for payments/check-ins).
struct PrimaryButton: View {
    let title: String
    var loading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if loading { ProgressView().tint(.white) }
                else { Text(title).font(AppFont.button) }
            }
            .frame(maxWidth: .infinity, minHeight: 50) // 44pt+ tap target
            .foregroundColor(.white)
            .background((disabled || loading) ? AppColor.accent.opacity(0.4) : AppColor.accent)
            .clipShape(Capsule())
        }
        .disabled(disabled || loading)
        .accessibilityLabel(title)
    }
}

// MARK: - Secondary button
// CALLOUT: Lower-emphasis action (outline). Used for non-primary actions like
// "Skip" or "Cancel" so the orange primary always stands alone on a screen.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(AppFont.button)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundColor(AppColor.ink)
                .overlay(Capsule().stroke(AppColor.hairline, lineWidth: 1))
        }
    }
}

// MARK: - Card container
// CALLOUT: Standard surface for grouped content (today's workout, metrics, etc.).
// Subtle elevation only, per the "calm/flat" principle (§7.3).
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(AppColor.hairline, lineWidth: 1))
    }
}

// MARK: - Status badge
// CALLOUT: Status pill that pairs an ICON with a label — never color alone —
// satisfying the accessibility rule in MVP §10 (don't rely on color).
struct StatusBadge: View {
    enum Kind { case neutral, success, warning, danger }
    let text: String
    var kind: Kind = .neutral
    var systemImage: String = "circle.fill"

    private var color: Color {
        switch kind {
        case .neutral: return AppColor.muted
        case .success: return AppColor.success
        case .warning: return AppColor.warning
        case .danger:  return AppColor.danger
        }
    }
    var body: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
            Text(text).font(AppFont.caption.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, Space.s).padding(.vertical, Space.xs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("\(text) status")
    }
}

// MARK: - Empty state
// CALLOUT: Reusable empty-state pattern (icon + one line + one CTA) mandated for
// every "no data" screen in MVP §9. Empty states must guide, never show "No data".
struct EmptyStateView: View {
    let icon: String
    let message: String
    var ctaTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: Space.l) {
            Image(systemName: icon).font(.system(size: 44)).foregroundColor(AppColor.accent)
            Text(message).font(AppFont.body).foregroundColor(AppColor.muted)
                .multilineTextAlignment(.center).padding(.horizontal, Space.xl)
            if let ctaTitle, let action {
                PrimaryButton(title: ctaTitle, action: action).padding(.horizontal, Space.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title).font(AppFont.h3).foregroundColor(AppColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Screen scaffold
// CALLOUT: Wraps every screen with the white background + navigation title so we
// never repeat boilerplate and the background stays consistently Claude-white.
struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView { VStack(spacing: Space.l) { content }.padding(Space.l) }
        }
        .navigationTitle(title)
    }
}
