# CoachOS iOS Client — QA Validation Report

> Authored to the `Agents/QA.md` Principal QA Engineer playbook. Risk-based, tied to the actual FRs in `MVP.md` / `DEVELOPER_REQUIREMENTS.md`. Validates the **client iOS app** in this repo.

## TL;DR QA Recommendation
The client app covers **all client-side FRs (FR-2, 5, 6, 7, 8, 9)** with correct business rules (offline-first logging, one-check-in-per-ISO-week, server-authoritative billing, unit-safe storage). **Conditional pass for the mock build.** Blockers to a real release are environmental, not functional: live API, Stripe/APNs/S3 wiring, and on-device verification (the code was authored carefully but has **not** been compiled on this machine — no iOS SDK here; first action is a clean Xcode build).

## Scope
In scope: the SwiftUI client (`CoachOSClient`). Out of scope: coach web SPA, backend, and any coach-only FR (FR-1, 3, 4, 10 coach side, FR-7.2 review) — not part of the iOS app.

## Assumptions
- Mock build under test; rules enforced in `MockAPIService` mirror the future backend.
- iOS 17 (latest) + iOS 16 (n-1) per `MVP §10.1`; iPhone 14 + iPhone SE.
- Offline behavior is demoed via the Account → Offline toggle.

## Test Strategy
Risk-weighted toward the three areas where client bugs hurt most: **(1) offline data loss** in workout logging, **(2) unit-conversion correctness** across log/display, **(3) billing state** never being assumed client-side. Happy-path + negative + edge + a11y per screen.

## Functional Test Cases

| ID | Scenario | Preconditions | Steps | Expected | Priority |
|----|----------|---------------|-------|----------|----------|
| TC-01 | Intake completes & app unlocks | Fresh launch, onboarding shown | Pick units, fill goal/height/weight/DOB, password ≥8, tap Start | Session set, Today appears; `client_invite_accepted` emitted | P0 |
| TC-02 | Intake rejects weak password | Onboarding | Enter 5-char password | Start button disabled | P1 |
| TC-03 | Today shows only today | Active client, program assigned | Open Home | Workout card + nutrition + habits + (due check-in); nothing else | P0 |
| TC-04 | Today empty state | No program | Home with no assignment | Friendly "coach is building your program", no blank widgets | P1 |
| TC-05 | Log sets, mark complete | Today workout available | Enter reps/load, tick each set, Mark complete | All sets required before enable; `workout_log_completed` emitted; Today flips to Completed | P0 |
| TC-06 | Logging survives app close | Mid-workout, partial sets | Enter 2 sets, kill app, reopen | Entered actuals persist (LocalStore) | P0 |
| TC-07 | Offline log + later sync | Account → Offline ON | Log sets offline (badge "Saved offline"), toggle Offline OFF | `pendingCount` drains, badge clears (last-write-wins) | P0 |
| TC-08 | Weight log + trend, unit-safe | Progress tab | Log 70 in kg, switch units to imperial in profile | Stored kg constant; chart/label re-render as lb with exact conversion | P0 |
| TC-09 | Check-in submits once/week | No check-in this week | Fill weight+ratings+notes, Send | Success; form replaced by "Submitted this week"; `check_in_submitted` emitted | P0 |
| TC-10 | Duplicate check-in blocked | Already checked in | Attempt again | Form hidden / API returns "already checked in this week" | P1 |
| TC-11 | Message send + read receipt | Coach tab | Send text | Bubble right-aligned orange, timestamp; inbound marked read on open | P1 |
| TC-12 | Polling refresh | Coach tab open | Wait 15s | `load()` re-fetches without manual refresh | P2 |
| TC-13 | Subscribe via hosted flow | Billing, status not active | Tap Subscribe | Returns Stripe **hosted** URL; no in-app card form rendered | P0 |
| TC-14 | Cancel keeps access to period end | Active subscription | Cancel | Status → Canceled, "Access until <date>" shown; `subscription_canceled` emitted | P1 |

## Edge Cases
- Rest day renders as a calm rest state, not an error (TodayView `isRest`).
- Rep **range** (8–12) displays correctly; single value collapses to "8".
- Empty progress/photos/messages each show a guiding empty state.
- Period-end date formatting respects locale.

## Negative Test Cases
- Invalid/empty invite token → `invalidInvite` friendly message (no "account exists" leak).
- Non-numeric weight → Send disabled.
- Offline submit of check-in → caught and surfaced, no crash.
- Billing never transitions to Active from the client without server confirmation.

## API / Data Validation
- All models are `Codable` and round-trip through `LocalStore` (JSON) — same types as the future REST DTOs (no drift).
- Weight/height stored in **base metric units**; display conversion centralized in `Units` (the only place math happens).
- Tenant fields (`clientId`, `coachId`) present on every record for server-side scoping.

## Analytics Validation
Verify each event fires exactly once with schema `{event, actor_id, actor_role, entity_id, metadata}`: `client_invite_accepted`, `workout_log_completed`, `metric_logged`, `progress_photo_uploaded`, `check_in_submitted`, `message_sent`, `subscription_canceled`. (Console sink in mock; assert in `LiveAPIService` integration tests.)

## Accessibility Checks
- Touch targets ≥44pt on set-completion toggle, rating circles, send button. ✅ in code.
- Status uses **icon + label**, never color alone (`StatusBadge`). ✅
- Dynamic Type: text uses system font styles; verify no clipping at XXL on device. ⚠️ verify on device.
- VoiceOver labels on buttons, ratings, badges. ✅ partial — audit all custom controls on device.
- Contrast: orange `#D97757` on white passes AA for large text/UI; **verify body-on-orange (white text) ≥4.5:1** — orange button text should be checked; consider darkening to `#C15F3C` if it fails. ⚠️

## Performance Checks
- Today/Progress load < 2s p95 (mock is instant; assert against live API).
- Chart renders 7+ points smoothly; verify with 90-day series.
- Polling every 15s — confirm task cancels on tab switch (battery). ✅ `onDisappear` cancels.

## Automation Candidates
- XCUITest: onboarding → Today → log workout → complete (smoke).
- XCUITest: offline log + sync drain.
- Unit tests: `Units` conversion table (kg↔lb, cm↔in) — highest ROI, pure logic.
- Unit tests: ISO-week duplicate-check-in rule.

## Device / OS Coverage
iOS 17 + iOS 16; iPhone 14 (notch) + iPhone SE (small, no Dynamic Island). Portrait only (Info.plist).

## Release Readiness Criteria
- [ ] Clean Xcode build + run on both target OS versions (first action).
- [ ] All P0/P1 cases pass on device.
- [ ] `Units` + ISO-week unit tests green.
- [ ] Contrast audit on orange CTAs passes AA.
- [ ] `LiveAPIService` integration tests for analytics + billing webhooks.
- [ ] Crash-free ≥99% in TestFlight (`MVP §10.4`).

## Risks
- **R1 (High):** Not yet compiler-verified in this environment — a missed type error could surface on first build. Mitigation: build immediately in Xcode.
- **R2 (Med):** Offline last-write-wins can silently overwrite concurrent edits; acceptable for single-device MVP, revisit for multi-device.
- **R3 (Med):** White-on-orange contrast may miss AA for small text — audit before launch.
- **R4 (Low):** `LocalStore` does synchronous file IO on main actor — fine at MVP scale, move off-main if logs grow.

## Open Questions
1. Does the client show a week view or only "today + next"? (Design open Q.)
2. Voice/image message attachments — in MVP client scope or text-only first?
3. Exact compliance window for any client-side display (coach dashboard owns the metric).
