# CoachOS — iOS Client App (Phase 1 MVP)

The native **client-facing** iOS app from `MVP.md`, built per the `SE.md` Principal Software Engineer playbook: clean architecture, clean seams, no over-engineering. It **runs today with no backend** against an in-memory mock, and swaps to the real API by changing one line.

> Scope note: per `MVP.md`, the iOS surface is the **client** app (coaches use the web SPA). The React coach web app and the Node/Postgres backend are separate, non-iOS deliverables and are out of scope for this codebase.

---

## What's implemented (every client-side FR)

| FR | Feature | Where |
|----|---------|-------|
| FR-2.2 | Invite accept + intake (goal, height, weight, units, DOB) | `Features/Auth/IntakeOnboardingView.swift` |
| FR-5.1 | Today view — workout / nutrition / habits / due check-in, all states | `Features/Today/TodayView.swift` |
| FR-5.2 | Workout logging, per-set actuals, note, offline-first + sync | `Features/Workout/WorkoutLoggingView.swift`, `Services/SyncEngine.swift` |
| FR-6.1 | Body-weight logging + trend chart (unit-aware) | `Features/Progress/ProgressDashboardView.swift` |
| FR-6.2 | Progress photos + privacy reassurance | same |
| FR-7.1 | Weekly check-in, 1–5 ratings, one-per-ISO-week rule | `Features/CheckIns/CheckInView.swift` |
| FR-8.1 | 1:1 messaging, polling, read receipts | `Features/Messaging/MessagesView.swift` |
| FR-9.2 | Subscribe (hosted Stripe), status, cancel | `Features/Billing/BillingView.swift` |
| §11 | Analytics events | `Services/Analytics.swift` |

## Architecture (one line)

`SwiftUI Views → @MainActor ViewModels → APIService protocol → { MockAPIService (now) | LiveAPIService (later) }`, with `LocalStore` + `SyncEngine` for offline. Design tokens (Claude **white / black / orange**) live in `Sources/DesignSystem/Theme.swift`.

## Build & run

Requires macOS + Xcode 15+. **The Xcode project is included — just open it:**

```bash
cd CoachOSClient
open CoachOSClient.xcodeproj
# Select an iOS 16+ simulator → Run (⌘R)
```

That's it — no XcodeGen, no extra tooling. (`project.yml` is still included if you ever want to regenerate the project with XcodeGen, but you don't need it.)

## Going from "runs" to "shippable to the App Store"

This codebase is the complete, themed, FR-complete client. To actually ship you additionally need (all have clean seams here):

1. Implement `LiveAPIService: APIService` against the real REST API and swap it in `CoachOSApp.swift`.
2. Real Stripe hosted-checkout session URL + APNs push certs.
3. S3 signed-URL upload for progress photos (replace the mock).
4. Apple Developer team / provisioning + App Store assets.

## Claude color theme

White `#FFFFFF` surfaces · near-black ink `#141413` · Claude orange `#D97757` (accent) — defined once as tokens and used everywhere.
