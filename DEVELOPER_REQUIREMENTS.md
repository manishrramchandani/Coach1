# CoachOS — Developer Requirements Document

> **The operating system for fitness coaches**
> Product Requirements (PRD) + Engineering Specification

| | |
|---|---|
| **Audience** | Junior Developers (engineering team) |
| **Scope** | Phase 1 MVP build |
| **Version** | 1.0 (Draft for review) |
| **Owner** | Product Management |
| **Status** | Ready for estimation |
| **Pairs with** | [`DESIGN_UX_SPECIFICATION.md`](./DESIGN_UX_SPECIFICATION.md) — same FR IDs, same scope |

---

## Table of contents

- [0. How to use this document](#0-how-to-use-this-document)
- [1. Product overview & vision](#1-product-overview--vision)
- [2. Target users](#2-target-users)
- [3. MVP scope (Phase 1)](#3-mvp-scope-phase-1)
- [4. Roles & permissions](#4-roles--permissions)
- [5. Functional requirements](#5-functional-requirements)
- [6. Non-functional requirements](#6-non-functional-requirements)
- [7. Information architecture & navigation](#7-information-architecture--navigation)
- [8. Recommended architecture & tech stack](#8-recommended-architecture--tech-stack)
- [9. Data model](#9-data-model)
- [10. API surface (illustrative)](#10-api-surface-illustrative)
- [11. Authentication & session details](#11-authentication--session-details)
- [12. Third-party integrations](#12-third-party-integrations)
- [13. Success metrics to instrument](#13-success-metrics-to-instrument)
- [14. Definition of Done](#14-definition-of-done)
- [15. Roadmap (build order & future phases)](#15-roadmap-build-order--future-phases)
- [16. Open questions & assumptions log](#16-open-questions--assumptions-log)
- [17. Glossary](#17-glossary)

---

## 0. How to use this document

This document tells you exactly what to build for the Phase 1 MVP and what "done" looks like. Read it top to bottom once before estimating. You do not need product or fitness expertise — every feature is written as a user story with concrete, testable acceptance criteria.

### Conventions

- **MUST / SHOULD / MAY** — priority. MUST = required for MVP launch. SHOULD = include if time allows. MAY = nice-to-have / future.
- **[ASSUMPTION]** — a decision Product made to remove ambiguity. If you disagree, raise it before building; do not silently change it.
- **FR-x.y** — Functional Requirement IDs. Use these in commits, PRs, and tickets (e.g. `feat(FR-3.2): add workout logging`).
- **Definition of Done** — [Section 14](#14-definition-of-done). A ticket is not finished until it meets every item there.

### If you are blocked

Anything marked `[ASSUMPTION]` or listed in [Section 16](#16-open-questions--assumptions-log) is a decision point. Ask in the team channel rather than guessing — a 2-minute question is cheaper than a 2-day rebuild.

---

## 1. Product overview & vision

**Product mission.** CoachOS is the simplest operating system for fitness coaches — the single place where a coach runs their entire business. It is not "just" a workout tracker or a program builder; it is the complete business operating system for fitness coaching.

**The problem we are solving.** Even after paying for coaching software, most coaches still juggle WhatsApp, Google Sheets, Stripe, Notes, Calendly, and Instagram. The market is crowded with feature-equivalent tools (Trainerize, TrueCoach, Everfit, Practice Better, and others), yet coaches continue to stitch together 5–7 separate apps to run one business.

**Our differentiation.** We do not win by re-listing the same features. We win by collapsing the coach's fragmented toolchain into one workflow, and by using automation to do the work coaches hate: building programs from scratch, chasing accountability, and summarizing check-ins. The four coach pain points below are the north star for every build decision.

### The four problems we exist to fix

| # | Coach pain point | How CoachOS responds |
|---|---|---|
| 1 | Too many tools (Instagram, Calendly, Stripe, WhatsApp, Sheets, Trainerize, Drive) | One platform: profile, payments, programs, tracking, messaging in a single workflow. |
| 2 | Program creation is tedious and repetitive | Reusable templates now; AI Program Builder in a later phase. |
| 3 | Client accountability is weak — clients stop checking in and disappear | Compliance tracking + an automated Accountability Engine (later phase) that flags drop-off. |
| 4 | Client experience is fragmented ("I hired a coach" → "download 5 apps") | A single, focused client app showing only today's tasks. |

> **[ASSUMPTION]** Phase 1 deliberately excludes the AI features and the public marketplace. Those are differentiators we build once the core coaching loop works (see [Section 15](#15-roadmap-build-order--future-phases)). Building the loop first lets us reach the Phase 1 goal: **10 coaches managing 100 clients.**

---

## 2. Target users

Two user types share the platform but use different surfaces. You will build for both.

| User | Who they are | Primary surface | What success means for them |
|---|---|---|---|
| **Coach** | Independent fitness coach running a small business (5–50 clients). Comfortable with tech but time-poor. | Coach web app (desktop-first) | Onboards a client and assigns a program in minutes; sees who is on track at a glance. |
| **Client** | A paying client following a coach's program. Mixed tech comfort. On their phone. | Client mobile app (iOS-first) | Opens the app and instantly knows what to do today; logs it in seconds. |

> **[ASSUMPTION] Platform split.** Coaches do program-building, dashboards, and payments — work that needs a large screen — so the coach app is a responsive web app (desktop-first). Clients need a fast, focused daily experience, so the client app is native iOS first. Both talk to one shared backend API. Android and a coach mobile app are future scope. Confirm with Product before assuming otherwise.

---

## 3. MVP scope (Phase 1)

### 3.1 In scope (MUST build)

1. Coach onboarding & account setup
2. Client onboarding via coach invitation
3. Program & workout builder (with reusable templates)
4. Program assignment to clients
5. Client workout tracking (the daily "Today" view + logging)
6. Progress tracking (body metrics + progress photos)
7. Weekly check-ins
8. 1:1 messaging (coach ↔ client)
9. Payments (client subscription billing to the coach)
10. Coach dashboard (active clients, revenue, compliance, upcoming check-ins)

### 3.2 Out of scope (do NOT build in Phase 1)

These are real features for later phases. Leave clean extension points but build none of them now.

- Public marketplace, coach discovery, search, reviews, success stories (Phase 2)
- AI Program Builder, AI Check-In Summaries, Coach Copilot (Phase 3)
- Automated Accountability Engine, group coaching, challenges, community/groups, referrals (Phase 3–4)
- Nutrition macro tracking beyond a simple coach-set daily target (Phase 2+)
- Native Android app and a coach-side native mobile app
- In-app video calling / consultation booking (use external links in Phase 1)

---

## 4. Roles & permissions

Authorization is enforced server-side on every request. Never trust the client to hide a button as the only protection.

| Capability | Coach | Client | Notes |
|---|---|---|---|
| Manage own profile | Yes | Yes | Each edits only their own. |
| Invite / remove clients | Yes | No | Coach owns the relationship. |
| Create programs & templates | Yes | No | |
| Assign program to a client | Yes | No | Only to their own clients. |
| View a client's data (logs, photos, metrics) | Yes (own clients only) | Own data only | Strict tenant isolation. |
| Log workouts / metrics / photos | No | Yes | Coach can view, not log on the client's behalf in MVP. |
| Submit check-ins | No | Yes | |
| Send messages | Yes | Yes | Within an existing coach–client pair. |
| Set / manage pricing & payouts | Yes | No | |
| Pay for a subscription | No | Yes | |

> **Tenant isolation is a hard rule.** A coach may only ever read or write data for clients linked to them. A client may only ever read or write their own data. Every data-access query MUST be scoped by the authenticated user's ID. Treat a cross-tenant data leak as a launch blocker.

---

## 5. Functional requirements

Each epic below has user stories with acceptance criteria. Acceptance criteria are your test cases — if you can tick every box, the story is done.

### 5.1 Coach onboarding & account (FR-1)

#### FR-1.1 — Coach sign-up
**As a** new coach, **I want** to create an account with email and password **so that** I can access the platform.

Acceptance criteria:
- Email + password sign-up with email format and password-strength validation (min 8 chars, at least 1 letter + 1 number).
- Duplicate email returns a clear, non-revealing error ("That email can't be used"), never "account exists".
- A verification email is sent; account is usable but shows an "unverified" banner until verified.
- Passwords are stored hashed (bcrypt/argon2) — never in plain text or reversible encryption.

#### FR-1.2 — Coach profile setup
**As a** coach, **I want** to complete my profile (name, photo, bio, specialties) **so that** clients see a credible coach.

Acceptance criteria:
- Editable fields: display name (required), profile photo, bio, specialties (multi-select), timezone.
- Profile photo upload accepts JPG/PNG up to 5 MB; oversized or wrong type is rejected with a clear message.
- "Profile complete" is true when name, photo, and at least one specialty are set — this drives the activation metric ([Section 13](#13-success-metrics-to-instrument)).

#### FR-1.3 — Coach login & session
**As a** returning coach, **I want** to log in securely and stay logged in **so that** I don't re-authenticate constantly.

Acceptance criteria:
- Successful login issues a session/JWT; tokens expire and refresh per [Section 11](#11-authentication--session-details).
- Logout invalidates the session.
- After 5 failed attempts, apply rate-limiting / temporary lockout.
- "Forgot password" sends a time-limited reset link (valid 60 min, single use).

### 5.2 Client onboarding (FR-2)

#### FR-2.1 — Coach invites a client
**As a** coach, **I want** to invite a client by email **so that** they can join my roster.

Acceptance criteria:
- Coach enters client email + name; system sends an invitation with a unique, expiring link (valid 7 days).
- Invitation appears in the coach's client list as status "Invited".
- Re-inviting the same email re-sends rather than creating a duplicate client.
- Coach can revoke a pending invitation.

#### FR-2.2 — Client accepts & onboards
**As an** invited client, **I want** to accept the invite and set up my account on iOS **so that** I can start my program.

Acceptance criteria:
- Tapping the invite link (or entering a code) opens sign-up pre-linked to the inviting coach.
- Client sets password and completes a short intake: goal, height, starting weight, units (kg/lb), date of birth.
- On completion, client status becomes "Active" and the coach is notified.
- Unit preference (metric/imperial) is stored and respected everywhere weight/height appear.

### 5.3 Program & workout builder (FR-3)

**Data shape:** a Program contains ordered Workout Days; each Workout Day contains ordered Exercises; each Exercise has prescribed sets, reps, and optional load/tempo/rest/notes. See the data model in [Section 9](#9-data-model).

#### FR-3.1 — Exercise library
**As a** coach, **I want** to pick from a library of exercises **so that** I don't retype exercise names.

Acceptance criteria:
- Seeded library of common exercises (name, primary muscle group, demo video URL).
- Coach can search/filter the library and add a custom exercise (custom exercises are private to that coach).

#### FR-3.2 — Build a program
**As a** coach, **I want** to create a multi-week program of workout days and exercises **so that** I can deliver structured training.

Acceptance criteria:
- Coach creates a Program with name, goal tag, and duration in weeks.
- Coach adds Workout Days; each day has a label (e.g. "Day 1 – Push") and an ordered list of exercises.
- Per exercise, coach sets: sets, reps (range allowed, e.g. 8–12), target load (optional), rest, tempo (optional), notes (optional).
- Exercises and days are reorderable (drag or up/down).
- Program saves as a draft and can be edited until assigned.

#### FR-3.3 — Templates (reuse)
**As a** coach, **I want** to save a program as a reusable template and start new programs from it **so that** I don't rebuild fat-loss / beginner / hypertrophy plans from scratch.

Acceptance criteria:
- Coach can save any program as a Template.
- Coach can create a new program from a template; edits to the new program do not affect the template.
- Templates are private to the coach who created them in MVP.

### 5.4 Program assignment (FR-4)

#### FR-4.1 — Assign a program to a client
**As a** coach, **I want** to assign a program to a specific client with a start date **so that** the client gets a daily schedule.

Acceptance criteria:
- Coach selects client + program + start date; system creates an Assignment that maps program days onto calendar dates.
- **[ASSUMPTION]** Scheduling model: workout days are sequenced from the start date; rest days are explicit days with no workout. Confirm whether programs are fixed-weekday or sequential before building — default is sequential.
- Only one active assignment per client at a time in MVP; assigning a new one ends the previous (with confirmation).
- Client is notified (push + in-app) that a new program is available.

### 5.5 Client workout tracking (FR-5)

#### FR-5.1 — Today view
**As a** client, **I want** to open the app and see only what I need to do today **so that** I'm not overwhelmed.

Acceptance criteria:
- Home shows today's workout (or "Rest day"), today's nutrition target, habits, and any due check-in — nothing else.
- If no program is assigned, show a friendly empty state explaining the coach will assign one.
- Past/future days are reachable but secondary to today.

#### FR-5.2 — Log a workout
**As a** client, **I want** to log my sets, reps, and weights as I train **so that** my coach can see compliance and progress.

Acceptance criteria:
- Client can mark each set complete and enter actual reps + load per set.
- Per-exercise and per-day completion state is saved and survives app close/reopen (offline-tolerant; see NFRs).
- Marking the day complete records a workout-completion event with a timestamp (drives compliance %).
- Client can add a note to the workout (e.g. "shoulder felt tight") visible to the coach.

### 5.6 Progress tracking (FR-6)

#### FR-6.1 — Log body metrics
**As a** client, **I want** to log my body weight (and optionally measurements) **so that** my coach can track the trend.

Acceptance criteria:
- Client logs weight with a date; entries are stored as a time series.
- Weight displays in the client's chosen units; conversions are exact and consistent.
- Client and coach see a simple trend chart over time.

#### FR-6.2 — Progress photos
**As a** client, **I want** to upload progress photos **so that** I can see my transformation and my coach can assess form/physique.

Acceptance criteria:
- Client uploads photos (JPG/PNG, max 10 MB each) tagged with a date.
- Photos are private to the client and their coach only — never public, never cross-tenant.
- Photos are stored in object storage with access-controlled, expiring URLs (not public buckets).

### 5.7 Weekly check-ins (FR-7)

#### FR-7.1 — Client submits a check-in
**As a** client, **I want** to submit a weekly check-in (weight, photos, notes, simple ratings) **so that** my coach can review my week.

Acceptance criteria:
- A check-in form collects: current weight, optional photos, free-text notes, and simple 1–5 ratings (e.g. energy, adherence, sleep).
- Submitting creates a check-in record tied to a week and notifies the coach.
- Client sees the status of past check-ins (Submitted / Reviewed).

#### FR-7.2 — Coach reviews & gives feedback
**As a** coach, **I want** to review a check-in and reply with feedback **so that** the client stays accountable and supported.

Acceptance criteria:
- Coach sees a queue of submitted check-ins (also surfaced on the dashboard, FR-10).
- Coach can read all submitted data and reply with text feedback.
- Replying marks the check-in "Reviewed" and notifies the client.

### 5.8 1:1 messaging (FR-8)

#### FR-8.1 — Coach–client messaging
**As a** coach or client, **I want** to exchange 1:1 text messages **so that** we don't need WhatsApp.

Acceptance criteria:
- A conversation exists per coach–client pair; either party can send text messages.
- New messages trigger a push + in-app notification to the recipient.
- Messages show timestamps and read state; history persists and paginates.
- MVP messaging includes Image, voice and near-real-time (polling or websocket acceptable).

### 5.9 Payments (FR-9)

> **[ASSUMPTION]** Use Stripe (Stripe Connect) so each coach receives payouts to their own account and the platform never holds funds directly. Do not build a payment processor. All card data is handled by Stripe — the app never sees or stores raw card numbers. Enable UPI Payments for India, wheeing coach can add their detials for the same.

#### FR-9.1 — Coach sets a price
**As a** coach, **I want** to set a monthly price for my coaching **so that** clients can subscribe.

Acceptance criteria:
- Coach connects a Stripe/UPI account (Stripe Connect onboarding) before they can charge.
- Coach sets a monthly subscription price and currency.
- Coach cannot accept payments until Stripe onboarding is complete; show a clear prompt until then.

#### FR-9.2 — Client subscribes
**As a** client, **I want** to pay my coach's monthly fee **so that** I get ongoing coaching.

Acceptance criteria:
- Client enters payment via Stripe's hosted/SDK flow (never a custom card form).
- On success, the client's billing status is "Active"; on failure, a clear retry path.
- Subscription state is driven by Stripe webhooks (active, past_due, canceled) — the app reacts to webhooks, it does not assume success client-side.
- Coach sees revenue and each client's billing status; client can cancel (access continues to period end).

### 5.10 Coach dashboard (FR-10)

#### FR-10.1 — Coach dashboard
**As a** coach, **I want** to see the health of my business at a glance **so that** I know where to spend my attention today.

Acceptance criteria:
- Dashboard shows: number of active clients, monthly revenue, overall compliance %, and upcoming/overdue check-ins.
- Compliance % = completed workouts ÷ scheduled workouts over a rolling window (define window in code comments; default 7 days).
- Each metric links to its detail view (clients list, payments, check-in queue).
- Empty/zero states are handled (new coach with no clients sees guidance, not blank widgets).

---

## 6. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | Today view and dashboard load in under 2s on a typical connection. List endpoints paginate (default 20/page). |
| Offline tolerance (client app) | Workout logging works offline and syncs when connectivity returns; no data loss on app close. Use local persistence + sync. |
| Security | All traffic over HTTPS/TLS. Auth on every endpoint. Server-side authorization + tenant scoping on every query. Rate-limit auth endpoints. |
| Privacy | Progress photos and health data are sensitive. Private storage, access-controlled URLs, no cross-tenant access, no third-party sharing. Support account deletion / data export (GDPR-style). |
| Secrets | No secrets, API keys, or Stripe keys in client code or the repo. Use environment config / a secrets manager. |
| Reliability | Payment state is reconciled via webhooks, not optimistic client assumptions. Webhook handlers are idempotent. |
| Observability | Structured logging, error tracking (e.g. Sentry), and basic metrics. No PII or health data in logs. |
| Accessibility | Meet the design spec's a11y bar (WCAG AA targets): labels, contrast, dynamic type, VoiceOver on iOS. |
| Localization-ready | Don't hard-code units or currency; respect user unit preference and Stripe currency. Strings centralized for future i18n. |

---

## 7. Information architecture & navigation

### 7.1 Coach app (iOS)

- **Dashboard** — active clients, revenue, compliance, upcoming check-ins
- **Clients** — client list → client profile (notes, programs, progress, check-ins, messages)
- **Programs** — templates, program builder, assignments
- **Payments** — revenue, payouts, transactions, billing status per client
- **Messages** — conversations with clients
- **Settings** — profile, availability, banking/Stripe

### 7.2 Client app (iOS)

- **Home (Today)** — today's workout, nutrition target, habits, due check-in
- **Workout** — the assigned workout + logging
- **Progress** — metrics + photos + trend
- **Coach** — messages + feedback
- **Account** — profile, billing

> **Note for engineers:** the client app's primary screen must surface only today's tasks. Resist adding navigation depth to the Home screen — it is the product's key differentiator against "download 5 apps" fragmentation.

---

## 8. Recommended architecture & tech stack

> **[ASSUMPTION]** The stack below is a recommended default chosen for junior-friendliness, a large hiring pool, and good docs. The team lead may substitute equivalents; if so, update this section. The architecture (one API serving two clients) should not change.

| Layer | Recommendation | Why |
|---|---|---|
| Client app | iOS native — Swift + SwiftUI | Per strategy's iOS focus; best daily UX and offline support. |
| Coach app | Web SPA — React + TypeScript | Desktop-first program building & dashboards; strong ecosystem. |
| Backend API | TypeScript (Node + NestJS/Express) or Python (FastAPI) | Single REST API serving both clients; pick one and standardize. |
| Database | PostgreSQL | Relational data (coaches, clients, programs, logs) fits naturally. |
| Object storage | S3-compatible (e.g. AWS S3) | Progress photos & exercise media via signed URLs. |
| Payments | Stripe + Stripe Connect | Never build payments; coaches get direct payouts. |
| Push notifications | APNs (iOS) via a service like FCM | Reminders, new-program, new-message, check-in alerts. |
| Auth | JWT access + refresh, or a managed auth provider | Stateless API auth; managed provider reduces risk. |

**Architecture in one line:** two clients (iOS + web) → one stateless REST API → PostgreSQL, with Stripe, object storage, and push as external services. Keep business logic in the API, not in the clients.

---

## 9. Data model

Core entities and key fields. Add timestamps (`created_at`, `updated_at`) and soft-delete where deletion must be reversible. IDs are UUIDs. This is a starting schema — refine during implementation but keep the relationships.

| Entity | Key fields | Relationships |
|---|---|---|
| User | id, role (coach\|client), email, password_hash, name, photo_url, timezone, unit_pref, created_at | Base for Coach & Client profiles. |
| CoachProfile | user_id, bio, specialties[], stripe_account_id, profile_complete | 1:1 with User (role=coach). |
| ClientProfile | user_id, coach_id, goal, dob, height, start_weight, status (invited\|active\|inactive) | Belongs to one Coach. |
| Invitation | id, coach_id, email, token, status, expires_at | Created by Coach; becomes a ClientProfile on accept. |
| Exercise | id, name, muscle_group, demo_url, owner_coach_id (null=global) | Global library + coach-custom. |
| Program | id, coach_id, name, goal_tag, duration_weeks, is_template, status | Has many WorkoutDays. |
| WorkoutDay | id, program_id, order_index, label | Has many ProgramExercises. |
| ProgramExercise | id, workout_day_id, exercise_id, order_index, sets, reps, load, rest, tempo, notes | Joins Exercise to a day. |
| Assignment | id, client_id, program_id, start_date, status | Maps a Program onto a Client's calendar. |
| WorkoutLog | id, assignment_id, client_id, scheduled_date, completed_at, note | One per scheduled workout. |
| SetLog | id, workout_log_id, program_exercise_id, set_index, actual_reps, actual_load, completed | Per-set actuals. |
| MetricEntry | id, client_id, type (weight\|measurement), value, unit, date | Time series. |
| ProgressPhoto | id, client_id, url, taken_on | Private to client + coach. |
| CheckIn | id, client_id, week_of, weight, ratings(json), notes, status, coach_feedback, reviewed_at | Weekly. |
| Message | id, conversation_id, sender_id, body, sent_at, read_at | Within a coach–client conversation. |
| Conversation | id, coach_id, client_id | 1 per coach–client pair. |
| Subscription | id, client_id, coach_id, stripe_subscription_id, status, current_period_end, price, currency | Driven by Stripe webhooks. |

---

## 10. API surface (illustrative)

A representative REST surface. Names may be refined, but keep resource-oriented design, server-side authorization, and tenant scoping. All endpoints require auth unless noted; all enforce that the caller may only touch their own / their clients' data.

| Method & path | Purpose | Who |
|---|---|---|
| `POST /auth/signup` | Create coach or client account | Public |
| `POST /auth/login` | Authenticate, return tokens | Public |
| `POST /auth/refresh` | Exchange refresh token | Authed |
| `GET/PATCH /me` | Read/update own profile | Coach, Client |
| `POST /coach/invitations` | Invite a client | Coach |
| `POST /invitations/:token/accept` | Accept invite, finish onboarding | Invited client |
| `GET /coach/clients` | List own clients (paginated) | Coach |
| `GET /coach/clients/:id` | Client detail (own client only) | Coach |
| `GET/POST /exercises` | Library read / add custom | Coach |
| `POST/PATCH /programs` | Create / edit program or template | Coach |
| `POST /programs/:id/assign` | Assign program to a client | Coach |
| `GET /client/today` | Today's workout + targets + check-in | Client |
| `POST /workout-logs/:id/sets` | Log set actuals | Client |
| `POST /workout-logs/:id/complete` | Mark workout complete | Client |
| `POST /metrics` | Log weight/measurement | Client |
| `POST /progress-photos` | Upload (signed URL flow) | Client |
| `POST /check-ins` | Submit weekly check-in | Client |
| `POST /check-ins/:id/feedback` | Coach review + feedback | Coach |
| `GET/POST /conversations/:id/messages` | Read/send messages | Coach, Client |
| `POST /billing/connect` | Start Stripe Connect onboarding | Coach |
| `POST /billing/subscribe` | Start client subscription | Client |
| `POST /webhooks/stripe` | Stripe events (idempotent) | Stripe (verified) |
| `GET /coach/dashboard` | Dashboard aggregates | Coach |

---

## 11. Authentication & session details

- Access token (short-lived, e.g. 15 min) + refresh token (longer-lived, rotating). Or use a managed auth provider.
- Store tokens securely on the client (iOS Keychain; web: httpOnly cookie or secure storage — avoid `localStorage` for refresh tokens).
- Every protected endpoint verifies the token and derives the user/role server-side. **Never accept a `user_id` from the request body to decide identity.**
- Rate-limit `/auth/login` and `/auth/signup`. Lock out after repeated failures.
- Password reset and email verification links are single-use and time-limited.

---

## 12. Third-party integrations

| Service | Used for | Key rules |
|---|---|---|
| Stripe (Connect) | Subscriptions, coach payouts | App never stores card data. State driven by verified, idempotent webhooks. |
| Object storage (S3) | Progress photos, exercise media | Private buckets; upload/download via short-lived signed URLs. |
| Push (APNs/FCM) | Reminders & alerts | No sensitive content in the notification body. |
| Email | Verification, invites, resets | Transactional provider; links are single-use + expiring. |

---

## 13. Success metrics to instrument

Build event tracking for these from day one — they define whether the MVP is working and must be queryable.

| Side | Metric | Definition / event to log |
|---|---|---|
| Coach | Activation | Profile completed (name + photo + ≥1 specialty). |
| Coach | Value | First client onboarded (status → active). |
| Coach | Retention | Weekly active coaches (logged in + took an action in 7 days). |
| Coach | Expansion | Additional clients added over time. |
| Client | Activation | First workout completed. |
| Client | Engagement | Weekly compliance (completed ÷ scheduled workouts). |
| Client | Retention | 30-day retention (active on day 30). |
| Client | Outcome | Program completion rate. |

---

## 14. Definition of Done

A ticket is done only when ALL of these are true:

1. Meets every acceptance criterion in its FR.
2. Server-side authorization + tenant scoping verified (a user cannot reach another tenant's data).
3. Inputs validated; error states return clear, non-leaky messages.
4. Automated tests cover the happy path + at least the key failure paths.
5. No secrets in code; config via environment.
6. Relevant success-metric events are emitted ([Section 13](#13-success-metrics-to-instrument)).
7. Code reviewed and merged via PR referencing the FR ID.
8. Manually verified on the target surface (iOS device/simulator or supported browser).

---

## 15. Roadmap (build order & future phases)

Build Phase 1 in this order so a usable coaching loop exists early. Later phases are out of scope now but should not be architecturally blocked.

**Phase 1 — MVP (this document)**
Coach onboarding → client onboarding → program assignment → workout tracking → progress tracking → payments → messaging. **Goal: 10 coaches managing 100 clients.**

**Phase 2 — Acquisition (future)**
Public marketplace, reviews, coach discovery/search. Goal: a coach-acquisition engine.

**Phase 3 — Intelligence (future)**
AI Program Builder, AI Check-In Summaries, Coach Copilot, automated Accountability Engine. Goal: 10× coach productivity. Design the data model so workout logs, check-ins, and compliance are clean inputs for these.

**Phase 4 — Network effects (future)**
Groups, challenges, community, referrals.

---

## 16. Open questions & assumptions log

Resolve these with Product before or early in the build. Each is a real decision, not a detail to invent.

1. Scheduling model: are workout days sequential from start date, or pinned to weekdays? *(Default assumed: sequential.)*
2. Can one client have multiple coaches or only one? *(Default assumed: one coach per client.)*
3. Nutrition in MVP: just a coach-set daily target, or simple macro fields? *(Default: single target only.)*
4. Messaging transport: polling vs websockets for near-real-time? *(Either acceptable for MVP.)*
5. Backend language: Node/TypeScript vs Python/FastAPI — lead to confirm and standardize.
6. Auth: build JWT in-house vs managed provider — lead to confirm.
7. Currencies/regions supported at launch (affects Stripe config).

---

## 17. Glossary

| Term | Meaning |
|---|---|
| Program | A multi-week training plan made of ordered workout days. |
| Template | A reusable program a coach copies to start new client programs. |
| Assignment | A program mapped onto a specific client's calendar from a start date. |
| Compliance | Completed workouts ÷ scheduled workouts over a rolling window. |
| Check-in | A weekly client submission (weight, photos, notes, ratings) the coach reviews. |
| Tenant isolation | The rule that a user can only access their own / their clients' data. |
| Stripe Connect | Stripe product that pays coaches directly; the platform doesn't hold funds. |

---

*Confidential — internal. CoachOS is a working product name; find-and-replace to rename.*
