# CoachOS — SourceCode (Phase 1 MVP)

Deliverable for the Coach1 project. Two parts:

| Folder | What |
|--------|------|
| `CoachOSClient/` | The native iOS **client** app (SwiftUI), built per `SE.md`. Runs against an in-memory mock with zero backend. Themed in Claude white/black/orange. See its `README.md`. |
| `QA/` | `QA_VALIDATION_REPORT.md` — validation of all client-side MVP requirements, authored per `QA.md`. |

## Quick start
```bash
brew install xcodegen
cd CoachOSClient && xcodegen generate && open CoachOSClient.xcodeproj
# Run on an iOS 16+ simulator
```

## Scope honesty
The iOS surface in `MVP.md` is the **client** app. The coach **web** SPA and the **backend** are separate, non-iOS deliverables and are not in this codebase. Every external dependency (REST API, Stripe, S3, APNs) sits behind a clean seam (`APIService` protocol) so the live versions drop in without touching views.
