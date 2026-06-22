# CoachOS — Design & UX Specification

> **The operating system for fitness coaches**
> Personas, flows, screen specs & design system

| | |
|---|---|
| **Audience** | Junior Designers (product & UI/UX) |
| **Scope** | Phase 1 MVP |
| **Version** | 1.0 (Draft for review) |
| **Owner** | Product Management |
| **Pairs with** | [`DEVELOPER_REQUIREMENTS.md`](./DEVELOPER_REQUIREMENTS.md) — same FR IDs, same scope |

---

## Table of contents

- [0. How to use this document](#0-how-to-use-this-document)
- [1. Design principles (the north star)](#1-design-principles-the-north-star)
- [2. Personas](#2-personas)
- [3. Information architecture & navigation](#3-information-architecture--navigation)
- [4. Core user flows](#4-core-user-flows)
- [5. Screen inventory (what to design)](#5-screen-inventory-what-to-design)
- [6. Screen specifications](#6-screen-specifications)
- [7. Design system](#7-design-system)
- [8. Content & microcopy](#8-content--microcopy)
- [9. States & edge cases (always design these)](#9-states--edge-cases-always-design-these)
- [10. Accessibility (required, not optional)](#10-accessibility-required-not-optional)
- [11. Platform & responsive notes](#11-platform--responsive-notes)
- [12. Design deliverables & handoff](#12-design-deliverables--handoff)
- [13. Open questions for design](#13-open-questions-for-design)
- [14. Glossary](#14-glossary)

---

## 0. How to use this document

This spec tells you what to design for the Phase 1 MVP, who you're designing for, and how it should feel. You do not need fitness expertise. Design the flows and screens listed here; everything maps to a feature the engineers are building (shared FR IDs).

### How to read it

- **Personas (§2)** — keep these two people in mind for every decision.
- **Flows (§4)** — the step-by-step journeys. Design the screens that make each step effortless.
- **Screen specs (§6)** — per screen: its goal, key elements, and the states you must design (not just the happy path).
- **Design system (§7)** — the tokens and components. Build these as reusable styles/components, not one-offs.
- **[ASSUMPTION]** — a Product decision made to remove ambiguity. Question it before building, don't silently change it.

### What "done" looks like for design

Deliverables are in [Section 12](#12-design-deliverables--handoff). In short: low-fi flows → hi-fi screens for every state → a documented component library → a developer-ready handoff (specs, tokens, assets).

---

## 1. Design principles (the north star)

CoachOS wins by replacing a coach's 5–7 disconnected tools (Instagram, Calendly, Stripe, WhatsApp, Sheets, Trainerize, Drive) with one calm workflow — and by giving clients a single app instead of "download 5 apps". Every design choice should serve that. Five principles:

| Principle | What it means in practice |
|---|---|
| **1. One place, not many** | Reduce tool-switching. If a task can live inside CoachOS, design it so the user never needs another app. |
| **2. Today over everything (client)** | The client's home shows only today's tasks: workout, nutrition target, habits, due check-in. Resist clutter — simplicity is the feature. |
| **3. Glanceable for coaches** | The coach's dashboard answers "who needs me today?" in seconds. Surface signal (compliance, due check-ins), hide noise. |
| **4. Motivation by progress** | Make progress visible and rewarding — streaks, trend lines, photo timelines. Clients stay because they can see change. |
| **5. Calm, credible, human** | This is someone's health and someone's livelihood. Clean, trustworthy, encouraging — never gamey or clinical. |

**Borrowed inspiration (do, don't copy):** clean minimal UX (Everfit), a clear program structure (Trainerize) without its interface complexity, and a strong accountability feel — habits and check-ins (Coach Catalyst).

---

## 2. Personas

### 2.1 Maya — the Coach

| Attribute | Detail |
|---|---|
| Who | Independent online fitness coach, 28. Runs her business solo with 5–30 clients. |
| Devices | Works on a laptop for programming and admin; checks her phone between sessions. |
| Goals | Onboard and program clients fast; keep clients accountable; get paid without chasing invoices. |
| Frustrations | Juggling WhatsApp, Sheets, Stripe, and Trainerize. Rebuilding the same plans. Clients ghosting. |
| Needs from CoachOS | Fast program building with templates, an at-a-glance dashboard, painless payments, one inbox. |
| Primary surface | Coach web app (desktop-first). |

### 2.2 Sam — the Client

| Attribute | Detail |
|---|---|
| Who | Busy professional, 34, hired Maya to lose fat and build a habit. Not a gym expert. |
| Devices | Phone-only. Uses the app at the gym and at home. |
| Goals | Know exactly what to do today and check it off; feel progress; reach Maya easily. |
| Frustrations | Confusing apps, too many notifications, not knowing if they're "doing it right." |
| Needs from CoachOS | A dead-simple "today" screen, quick logging, visible progress, a direct line to the coach. |
| Primary surface | Client iOS app. |

---

## 3. Information architecture & navigation

### 3.1 Coach app (web, desktop-first)

Left-side primary navigation; content area on the right.

- **Dashboard** — active clients, revenue, compliance, upcoming check-ins
- **Clients** — list → client profile (notes, programs, progress, check-ins, messages)
- **Programs** — templates, builder, assignments
- **Payments** — revenue, payouts, transactions
- **Messages** — conversations
- **Settings** — profile, availability, banking

### 3.2 Client app (iOS)

Bottom tab bar, 5 tabs max. Home is the default and the star of the show.

- **Home (Today)** — today's workout, nutrition target, habits, due check-in
- **Workout** — the assigned workout + logging
- **Progress** — metrics, photos, trend
- **Coach** — messages & feedback
- **Account** — profile, billing

---

## 4. Core user flows

Design the screens that make each numbered step effortless. Each flow maps to engineering FRs of the same area.

### 4.1 Coach flows

**UF-C1 — Coach sign-up & profile setup**
1. Coach signs up (email + password).
2. Verifies email (banner until verified — design the unverified state).
3. Completes profile: name, photo, bio, specialties, timezone.
4. Lands on an (empty) dashboard with a clear "invite your first client" prompt.

**UF-C2 — Invite & onboard a client**
1. From Clients (or dashboard prompt), coach taps "Invite client".
2. Enters client name + email; sends invite. Client appears as "Invited".
3. Coach sees status change to "Active" once the client finishes onboarding.

**UF-C3 — Build a program from a template**
1. Coach opens Programs → New → start blank or from a template.
2. Adds workout days; adds exercises from the library to each day.
3. Sets sets/reps/load/rest per exercise; reorders days and exercises.
4. Saves as draft; optionally saves as a reusable template.

**UF-C4 — Assign a program**
1. Coach opens a client → Assign program.
2. Picks a program + start date; confirms.
3. Client is notified; coach sees the assignment on the client profile.

**UF-C5 — Review a check-in & reply**
1. Dashboard shows "due/overdue check-ins"; coach opens the queue.
2. Reads weight, photos, ratings, notes; writes feedback.
3. Sends → check-in marked "Reviewed"; client notified.

**UF-C6 — Get paid**
1. Coach connects Stripe (one-time onboarding) from Settings/Payments.
2. Sets a monthly price; clients can now subscribe.
3. Coach views revenue and per-client billing status.

### 4.2 Client flows

**UF-S1 — Accept invite & onboard (iOS)**
1. Client taps the invite link / enters code → sign-up pre-linked to the coach.
2. Sets password; completes intake: goal, height, starting weight, units, date of birth.
3. Lands on Home with a friendly "your coach will assign your program" state if none yet.

**UF-S2 — Do today's workout**
1. Opens app → Home shows today's workout.
2. Taps in → logs sets, reps, weights; can add a note.
3. Marks workout complete → sees a small win (streak / completion).

**UF-S3 — Log progress**
1. Goes to Progress → logs weight; optionally uploads a progress photo.
2. Sees the trend line and the photo timeline update.

**UF-S4 — Submit a weekly check-in**
1. Home surfaces a "check-in due" prompt.
2. Fills weight, photos, ratings (energy/sleep/adherence), notes; submits.
3. Later sees coach feedback and a "Reviewed" status.

**UF-S5 — Message the coach**
1. Opens Coach tab → conversation.
2. Sends a message; sees timestamps + read state; gets notified of replies.

---

## 5. Screen inventory (what to design)

Minimum screen set for the MVP. Design each in every state listed in [Section 6](#6-screen-specifications). **C** = coach web, **S** = client iOS.

| Surface | Screens |
|---|---|
| Coach (web) | Sign-up / login, Profile setup, Dashboard, Clients list, Client profile, Program builder, Exercise picker, Assign program, Check-in queue & detail, Messages, Payments/Stripe setup, Settings. |
| Client (iOS) | Onboarding / intake, Home (Today), Workout detail & logging, Progress (metrics + photos + trend), Check-in form, Coach/messages, Account/billing. |

---

## 6. Screen specifications

Per screen: its goal, key elements, and the states you must design. "States" always include empty, loading, error, and success/filled where relevant — not just the happy path.

### 6.1 Coach — Dashboard (C / FR-10)

**SC-1 — Coach Dashboard**
**Goal:** Answer "who needs me today?" in one glance.

Key elements:
- Summary cards: active clients, monthly revenue, overall compliance %.
- "Upcoming / overdue check-ins" list with quick access.
- Each card links to its detail (clients, payments, check-in queue).
- Primary action for new coaches: "Invite your first client."

States to design:
- Empty (new coach, no clients) — guidance + invite CTA, not blank widgets.
- Loading — skeletons for cards/list.
- Populated — real numbers, sorted check-ins.
- Error — a card fails to load (graceful, retry).

### 6.2 Coach — Program builder (C / FR-3)

**SC-2 — Program Builder**
**Goal:** Let Maya build a multi-week program fast and reuse it.

Key elements:
- Program header: name, goal tag, duration (weeks).
- Workout days list (add / reorder / label, e.g. "Day 1 – Push").
- Per day: ordered exercises from the library; per exercise sets, reps (range), load, rest, tempo, notes.
- Exercise picker (search + filter + add custom).
- Save as draft; "Save as template."

States to design:
- Empty program (no days yet) — prompt to add the first day.
- Adding/editing an exercise — inline or modal entry.
- Reordering — clear drag affordance.
- Draft saved confirmation; validation errors (missing name/sets).

### 6.3 Coach — Client profile (C / FR-2, 6, 7)

**SC-3 — Client Profile**
**Goal:** Give Maya one view of a single client.

Key elements:
- Header: client name, goal, status, billing status.
- Tabs/sections: programs/assignment, progress (weight trend + photos), check-ins, notes, messages.
- Primary actions: assign program, message, review check-in.

States to design:
- Newly invited (not yet active) — limited data, "awaiting onboarding."
- Active with data — trends and history visible.
- No progress logged yet — empty progress state.

### 6.4 Client — Home / Today (S / FR-5)

**SS-1 — Home (Today)**
**Goal:** Sam opens the app and instantly knows what to do today.

Key elements:
- Today's workout card (or "Rest day").
- Nutrition target for today.
- Habits checklist.
- "Check-in due" prompt when applicable.
- Nothing else — keep it to today.

States to design:
- No program assigned — friendly "your coach will assign your program".
- Rest day — clearly a rest day, not an error.
- Workout available — primary CTA to start.
- Workout already completed today — celebratory completed state.
- Loading / offline (cached today).

### 6.5 Client — Workout & logging (S / FR-5)

**SS-2 — Workout detail & logging**
**Goal:** Make logging sets effortless mid-workout.

Key elements:
- Ordered exercise list with prescribed sets/reps/load.
- Per set: mark complete + enter actual reps & load (large tap targets, gym-friendly).
- Add a workout note (e.g. "shoulder tight").
- "Mark workout complete" primary action.

States to design:
- Not started — prescribed values shown.
- In progress — partial completion saved (survives app close).
- Offline — logs locally, syncs later (no data-loss messaging).
- Completed — confirmation + small win (streak).

### 6.6 Client — Progress (S / FR-6)

**SS-3 — Progress**
**Goal:** Make change visible so Sam stays motivated.

Key elements:
- Weight entry + trend line over time (respects unit preference).
- Progress-photo upload + a transformation timeline (Day 1 → 30 → 60 → 90).
- Privacy reassurance: visible only to Sam and the coach.

States to design:
- No entries yet — encouraging empty state + first-log CTA.
- With data — trend + photo timeline.
- Upload in progress / failed (retry).

### 6.7 Client — Check-in form (S / FR-7)

**SS-4 — Weekly check-in**
**Goal:** A low-friction weekly ritual.

Key elements:
- Fields: current weight, optional photos, simple 1–5 ratings (energy, sleep, adherence), notes.
- Clear submit; reassurance the coach will review.
- After review: shows coach feedback + "Reviewed."

States to design:
- Due (not started) — prompted from Home.
- Submitted, awaiting review.
- Reviewed — feedback visible.
- Validation (missing weight).

### 6.8 Client — Onboarding / intake (S / FR-2)

**SS-5 — Onboarding / intake**
**Goal:** Get Sam set up in under a minute.

Key elements:
- Accept invite (pre-linked to coach).
- Set password.
- Short intake: goal, height, starting weight, units, date of birth.
- Warm welcome → Home.

States to design:
- Invalid/expired invite link — clear recovery message.
- Step-by-step progress (don't ask everything on one dense screen).
- Completion → success + handoff to Home.

---

## 7. Design system

> **[ASSUMPTION]** The tokens below are a recommended starting system, tuned to the calm/credible/encouraging brand. Refine with Product, then lock them as reusable styles/components. Keep one shared visual language across coach web and client iOS so the product feels like one tool.

### 7.1 Color

| Token | Hex | Usage |
|---|---|---|
| Primary / Teal | `#0F766E` | Primary actions, active states, key accents. |
| Ink / Navy | `#0B2545` | Headings, primary text on light backgrounds. |
| Success | `#1B873F` | Completion, streaks, positive trends. |
| Warning | `#B45309` | Overdue check-ins, past-due billing, attention needed. |
| Danger | `#B91C1C` | Errors, destructive actions. |
| Muted text | `#5B6470` | Secondary text, metadata, timestamps. |
| Surface / BG | `#F5F8F8` | App background, cards, zebra rows. |

**Contrast:** all text/background pairings must meet WCAG AA (4.5:1 for body text, 3:1 for large text). Never rely on color alone to convey state — pair with an icon or label.

### 7.2 Typography

> **[ASSUMPTION]** Use one clean, friendly sans-serif across both platforms (e.g. Inter on web; SF Pro / system font on iOS). Confirm the brand typeface with Product.

| Style | Size / weight | Use |
|---|---|---|
| Display / H1 | 28–32, bold | Screen titles, big numbers on dashboard. |
| H2 | 22–24, semibold | Section headers. |
| H3 | 18–20, semibold | Card titles, group labels. |
| Body | 16, regular | Default text. 16px minimum on mobile for readability. |
| Caption | 13–14, regular | Metadata, timestamps, helper text. |
| Button | 16, semibold | Action labels. |

### 7.3 Spacing, radius, elevation

- **Spacing scale (4pt base):** 4, 8, 12, 16, 24, 32, 48. Use consistently; avoid arbitrary values.
- **Corner radius:** 8px default for cards/inputs; 12–16px for large cards / sheets; pill for primary buttons if on-brand.
- **Elevation:** subtle shadows for cards and modals only; keep the UI flat and calm elsewhere.
- **Touch targets (iOS):** minimum 44×44pt — critical for gym-floor logging.

### 7.4 Core components

Design these once as reusable components, with all states (default, hover/pressed, focus, disabled, loading, error):

| Component | Notes / required states |
|---|---|
| Buttons | Primary, secondary, tertiary/text, destructive. States: default, pressed, disabled, loading. |
| Inputs & forms | Text, number (reps/load), select/multi-select (specialties), date. States: empty, focus, filled, error, disabled. |
| Cards | Dashboard metric card, today's-workout card, client card. Include empty variants. |
| List rows | Client row (with status), exercise row, message row, check-in row. |
| Tabs / segmented control | Client profile sections; iOS bottom tab bar (5 tabs). |
| Charts | Weight trend line; compliance indicator. Keep simple and legible. |
| Badges / status | Invited / Active, Submitted / Reviewed, Active / Past-due. Icon + label, not color alone. |
| Empty states | Reusable pattern: illustration/icon + one line + one CTA. |
| Toasts / alerts | Success, error, info. Non-blocking where possible. |
| Modals / sheets | Confirmations (e.g. reassigning a program), exercise picker. |

---

## 8. Content & microcopy

- **Tone:** warm, plain, encouraging. Talk like a supportive coach, not a corporate app.
- **Empty states motivate:** "Your coach will assign your program soon — you'll see today's workout right here." not "No data."
- **Errors are kind & actionable:** say what happened and what to do next; never blame the user; never expose technical detail.
- **Privacy reassurance:** near photo upload, state plainly that photos are visible only to the client and their coach.
- **Buttons are verbs:** "Assign program," "Log workout," "Send feedback" — not "Submit" / "OK."
- **Respect units:** show kg or lb per the user's preference everywhere weight appears.

---

## 9. States & edge cases (always design these)

| State | Design it for… |
|---|---|
| Empty | First-run, no clients, no program, no progress logged, no messages. Always give a next step. |
| Loading | Skeletons for dashboards/lists; spinners only for short waits. |
| Error | Failed load, failed upload, failed payment, expired invite — each with a clear recovery action. |
| Offline (client) | Workout logging continues offline and syncs later; reassure, don't alarm. |
| Success | Workout complete, check-in submitted, payment active — small, satisfying confirmations. |
| Permission / status | Unverified email, Stripe not connected, client awaiting onboarding, subscription past-due. |

---

## 10. Accessibility (required, not optional)

- **Contrast:** WCAG AA minimum (4.5:1 body, 3:1 large text & meaningful icons).
- **Don't rely on color alone:** pair status color with an icon or label.
- **Touch targets:** ≥44×44pt on iOS; comfortable click targets on web.
- **Dynamic type:** layouts must survive larger system font sizes without clipping.
- **Screen readers:** every control has an accessible label; design with VoiceOver in mind on iOS.
- **Focus & keyboard (web):** logical focus order and visible focus states for the coach app.
- **Motion:** keep animation subtle; respect "reduce motion."

---

## 11. Platform & responsive notes

- **Client = iOS-first:** design to iPhone sizes; bottom tab navigation; thumb-reachable primary actions.
- **Coach = web, desktop-first:** optimize for laptop/desktop where programming and dashboards happen; ensure it remains usable down to tablet width.
- **One visual language:** shared colors, type, and component logic so coach and client clearly belong to the same product.
- **[ASSUMPTION]** Android and a coach mobile app are future scope — don't design them now, but don't make choices that would block them.

---

## 12. Design deliverables & handoff

"Done" for the design phase means all of the following exist and are reviewed:

1. Low-fidelity flows for every flow in [Section 4](#4-core-user-flows) (UF-C1…UF-S5).
2. High-fidelity screens for every screen in [Section 5](#5-screen-inventory-what-to-design), in every state from [Section 9](#9-states--edge-cases-always-design-these).
3. A documented component library ([Section 7](#7-design-system)) with all interactive states.
4. Design tokens (color, type, spacing, radius) defined and named, ready for engineering.
5. Exported assets and icons in the formats engineering needs (e.g. SVG, @2x/@3x for iOS).
6. Redlines / spacing specs or an inspectable handoff (e.g. dev-mode in your design tool).
7. Microcopy for empty/error/success states ([Section 8](#8-content--microcopy)) written, not placeholder "lorem."
8. Accessibility checklist ([Section 10](#10-accessibility-required-not-optional)) passed on key screens.

**Work in this order:** flows first (get the journey right), then one polished "golden path" per surface for sign-off, then expand to all states, then componentize and document. Don't polish pixels before the flow is approved.

---

## 13. Open questions for design

1. Brand: confirm the primary typeface, logo, and whether the teal/navy palette is final.
2. Scheduling display: do clients see a week view or only "today + next"? *(Engineering default: sequential days.)*
3. How much nutrition UI in MVP — a single daily target, or simple macros? *(Default: single target.)*
4. Streaks/gamification depth — how celebratory without feeling "gamey"?
5. Does the coach need a read-only mobile view in MVP, or strictly desktop web?

---

## 14. Glossary

| Term | Meaning |
|---|---|
| Today view | The client's home screen showing only today's tasks — the product's signature simplicity. |
| Program / Template | A multi-week plan; a template is a reusable version coaches copy. |
| Assignment | A program mapped onto a client's calendar from a start date. |
| Check-in | A weekly client submission (weight, photos, ratings, notes) the coach reviews. |
| Compliance | Completed vs scheduled workouts — shown to coaches as a health signal. |
| State | A distinct version of a screen (empty, loading, error, success, etc.) you must design. |
| Design token | A named, reusable value (color, spacing, type) shared with engineering. |

---

*Confidential — internal. CoachOS is a working product name; find-and-replace to rename.*
