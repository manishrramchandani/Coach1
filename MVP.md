# CoachOS — Phase 1 MVP Build Plan

> Cross-discipline spec synthesized by Product, UX, Software Engineering, QA, and Database Architecture leads. Read end-to-end once before building. Every section calls out the owner that set the guidance.

## 0. Exec summary (PM)
- **Mission:** Ship a production-ready loop that lets 10 coaches manage 100 clients end-to-end inside CoachOS.
- **MVP outcome:** Coaches can onboard clients, assign structured programs, review adherence, message, and get paid without leaving the platform. Clients get a focused iOS app that shows only what to do today and logs progress offline.
- **Guardrails:** Phase 1 excludes AI/autonomy, public discovery, Android, and deep nutrition tracking. Build clean extension points but no hidden scope.

## 1. Personas, jobs, and success targets (PM)
| Persona | Primary surface | Job to be done | Success metric |
| --- | --- | --- | --- |
| **Coach (solo/SMB)** | Web SPA (desktop-first) | Onboard clients quickly, reuse programs, see who needs attention, collect payments. | Profile completion, first client active, weekly active coaches, revenue per coach. |
| **Client (iOS-first)** | Native iOS app | Know exactly what to do today, log workouts/metrics, stay accountable. | First workout logged, weekly compliance %, 30-day retention. |

Success events must be instrumented from day one (Section 11).

## 2. Experience blueprint (UX)
### 2.1 Coach happy path
1. **Sign up & verify email.** Banner until verified.
2. **Complete profile** (name, headshot, bio, specialties, timezone). Drives activation KPI.
3. **Invite clients** via email, monitor invite status, resend/revoke.
4. **Build program** using exercise library + templates.
5. **Assign program** with start date (sequential scheduling default). One active assignment per client.
6. **Monitor dashboard** for compliance %, upcoming check-ins, revenue, billing status.
7. **Review weekly check-ins** and reply.
8. **Message** clients 1:1 with text + images + audio snippets.
9. **Connect Stripe/UPI** and set monthly pricing. View payouts and billing state per client.

### 2.2 Client happy path
1. **Accept invite** from email → deep link into iOS onboarding (pre-linked coach).
2. **Complete intake**: goals, height, starting weight, DOB, units.
3. **Land on Today view**: workout (or rest), nutrition target, habits, due check-in.
4. **Log workout** with per-set actual reps/load, add notes, mark complete (offline tolerant).
5. **Track progress**: weight trend, photos (secure storage), compliance badge.
6. **Submit weekly check-in** (weight, photos, notes, 1–5 ratings) → coach notified.
7. **Message coach** directly from Coach tab.
8. **Manage subscription**: view billing status, cancel (access thru period end).

### 2.3 UX principles
- Home/Today shows *only* actionable items. Past/future accessible but secondary.
- Empty states provide guidance (e.g., “Your coach is building your first program”).
- Support Dynamic Type, VoiceOver labels, high contrast, and large tap targets (44pt).

## 3. Functional requirements (all disciplines)
Each FR inherits acceptance criteria from `DEVELOPER_REQUIREMENTS.md` plus clarifications below.

### FR-1 Coach onboarding
- **Sign-up:** Email/password with strength validation, email verification, lockout after 5 failures.
- **Profile:** Required fields: name, photo (≤5 MB JPG/PNG), ≥1 specialty, timezone. Track `profile_complete` boolean.
- **Session:** JWT + refresh or managed auth; tokens rotated per Section 8.

### FR-2 Client onboarding
- **Invites:** Unique token valid 7 days, resend instead of duplicate, revoke allowed.
- **Acceptance:** Intake collects units preference (stored on profile) and minimal biometrics. Coach push notification + email when client activates.

### FR-3 Program & workout builder
- **Exercise library:** Seed data + coach-specific customs. Search/filter by muscle group.
- **Program authoring:** Multi-week structure, ordered workout days, per-exercise parameters (sets, reps range, optional load/rest/tempo/notes). Draft status until assigned.
- **Templates:** Flag any program as template; cloning breaks reference.

### FR-4 Program assignment
- **Scheduling decision:** Default sequential day offset from start date. Store `assignment.schedule_type` to allow future weekday mode. Changing schedule re-generates pending `WorkoutLog` placeholders.
- **Single active assignment:** Assigning another auto-ends previous after confirmation dialog.

### FR-5 Client workout tracking
- **Today view:** Shows today’s scheduled workout, nutrition target field (single number per coach), habits checklist (simple text items), due check-in card.
- **Logging:** `WorkoutLog` + `SetLog` records created ahead of time when assignment starts. Offline-first persistence via local DB; sync resolves conflicts by last-write wins plus merge UI for duplicates.
- **Completion:** `completed_at` timestamp + optional note; emits compliance event.

### FR-6 Progress tracking
- **Metrics:** `MetricEntry` time series. Respect unit preference with precise conversion (store base metric units).
- **Photos:** Upload flow uses pre-signed URLs, store metadata (orientation, file size) for downstream AI phases.

### FR-7 Weekly check-ins
- **Client form:** Weight, optional photos (reuse upload flow), free-text notes, ratings JSON schema (energy, adherence, sleep). Prevent duplicate submission in same ISO week.
- **Coach review:** Queue prioritized by `submitted_at`; response marks status `reviewed`, includes timestamp + author.

### FR-8 Messaging
- **Transport:** MVP uses HTTP long-polling every 15s; wrap in service layer so WebSocket swap is isolated.
- **Payload:** Text required; allow single image or voice clip ≤1 MB per message. Media stored via same signed URL mechanism.
- **Read receipts:** Track per-user `read_at` on `ConversationParticipant` join table.

### FR-9 Payments
- **Stripe Connect + UPI:** Coaches must finish Stripe onboarding *and* provide UPI info (stored encrypted) before publishing price. Use Stripe Checkout/Customer Portal for card entry; for UPI, leverage Stripe’s UPI support (India-based coaches) and store customer billing agreements per Stripe IDs.
- **Subscriptions:** State machine driven solely by webhook events (`invoice.payment_succeeded`, `payment_failed`, `customer.subscription.deleted`). Webhooks idempotent; log `event_id` table.

### FR-10 Coach dashboard
- **Metrics:** Active clients, MRR, 7-day compliance %, upcoming/overdue check-ins. Each card links to filtered view. Provide helper text for zero-data states.

## 4. Non-functional requirements (SE)
| Category | Requirement |
| --- | --- |
| Performance | Today view & dashboard SSR/API <2 s p95. All list endpoints paginated (20 default, max 100). |
| Offline | Client app caches assignments, workout logs, messages (last 50) locally using Core Data/Realm. Sync status shown per workout. |
| Security | HTTPS everywhere, JWT validation + role-based authorization per request, tenant scoping in every query. Rate-limit auth endpoints (5/min IP burst). |
| Privacy | Progress photos + health data in private S3 bucket with 15-min signed URLs. Provide GDPR-style delete/export endpoints (queue background job). |
| Observability | Structured JSON logging (exclude PII), Sentry for clients + backend, metrics for auth failures, webhook failures, sync lag. |
| Accessibility | WCAG AA: contrast, semantic labels, VoiceOver order, haptics sparingly. |
| Localization-ready | Store strings in localization files, never concatenate units, respect currency formatting from Stripe. |

## 5. System architecture (SE)
- **Clients:**
  - iOS app (SwiftUI + Combine). Modules: Auth, Today, Workouts, Progress, Check-Ins, Messaging, Billing.
  - Coach web SPA (React + TypeScript + TanStack Query). Routes mirror IA.
- **API:** Node.js (NestJS) REST service (alternatively FastAPI; pick one and stick). Stateless containers, JWT auth middleware, Prisma/SQLAlchemy ORM.
- **Services:** PostgreSQL (primary data), Redis (sessions, rate limiting, background job queues), S3 (photos/media), Stripe, APNs/FCM bridge, email provider (Postmark).
- **Deployment:** API + web via container orchestrator (ECS/Kubernetes) or managed PaaS; iOS via TestFlight. CI/CD with lint, tests, type-checks, deploy gates.
- **Background jobs:** Invitation expiry sweeper, webhook handlers, photo thumbnailer, compliance recompute, analytics event forwarder.

## 6. Data model (Database Architect)
Key tables (all UUID PKs, created/updated timestamps, soft delete where recovery needed).

```sql
-- Users and profiles
users(id, role, email, password_hash, name, photo_url, timezone, unit_pref, email_verified_at)
coach_profiles(user_id PK/FK, bio, specialties text[], stripe_account_id, upi_vpa_encrypted, profile_complete boolean)
client_profiles(user_id PK/FK, coach_id FK users, goal, dob, height_cm, start_weight_kg, status enum, unit_pref_override)

-- Invitations & relationships
invitations(id, coach_id, email, token, status enum, expires_at)
conversations(id, coach_id, client_id, last_message_at)
conversation_participants(conversation_id, user_id, read_at)
messages(id, conversation_id, sender_id, message_type enum, body, media_url, media_thumb_url, sent_at)

-- Programs & assignments
exercises(id, owner_coach_id nullable, name, muscle_group, demo_url)
programs(id, coach_id, name, goal_tag, duration_weeks, is_template, status enum)
workout_days(id, program_id, order_index, label)
program_exercises(id, workout_day_id, exercise_id, order_index, sets, reps_lower, reps_upper, target_load, rest_seconds, tempo, notes)
assignments(id, client_id, program_id, start_date, schedule_type enum default 'sequential', status enum)

-- Execution data
workout_logs(id, assignment_id, client_id, scheduled_date, completed_at, note)
set_logs(id, workout_log_id, program_exercise_id, set_index, actual_reps, actual_load, completed boolean)
metric_entries(id, client_id, metric_type enum, value_numeric, unit, recorded_on)
progress_photos(id, client_id, s3_key, taken_on, file_size_bytes, orientation)
check_ins(id, client_id, week_of ISO week, weight_kg, ratings jsonb, notes, status enum, coach_feedback, reviewed_at)

-- Billing
subscriptions(id, coach_id, client_id, stripe_customer_id, stripe_subscription_id, status enum, price_cents, currency, current_period_end)
stripe_events(id, event_id unique, type, payload jsonb, processed_at)
```

Indexes: tenant filters (`coach_id`, `client_id`), `workout_logs(client_id, scheduled_date)`, `messages(conversation_id, sent_at)`, `stripe_events(event_id)` unique, `assignments(client_id, status)`.

## 7. API contracts (SE)
Provide OpenAPI spec during implementation. Critical endpoints:
- Auth (`/auth/signup`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/password-reset`).
- Coach resources: `/coach/profile`, `/coach/invitations`, `/coach/clients`, `/coach/dashboard`, `/programs`, `/programs/:id/assign`, `/payments/pricing`, `/billing/connect`, `/billing/subscription-status`.
- Client resources: `/client/today`, `/client/workout-logs`, `/metrics`, `/progress-photos`, `/check-ins`, `/conversations/:id/messages`, `/billing/subscribe`, `/billing/cancel`.
- Webhooks: `/webhooks/stripe` (verify signature, idempotent), `/webhooks/push-status` (optional future).
All endpoints enforce role + tenant scope server-side. Pagination via `?page=` + `?page_size=` with defaults.

## 8. Authentication, authorization, and security (SE)
- JWT access (15 min) + refresh (30 days) stored securely (Keychain, httpOnly cookie). Rotate refresh on each use.
- Rate limit auth endpoints (burst 5/min IP) and invite acceptance (to prevent brute force).
- Password policy: ≥8 chars, 1 letter + 1 number, block top breached passwords list.
- Signed URLs expire in ≤15 min; clients upload using PUT with required headers.
- Tenant isolation enforced in every ORM query helper (e.g., `where coach_id = ctx.user.id`). Add unit tests for cross-tenant access.

## 9. Integrations (SE)
- **Stripe Connect Standard:** Use onboarding link flow. Store returned account ID and requirements status. Listen to `account.updated` for KYC.
- **UPI:** Use Stripe’s UPI payment method; capture VPA from client, tokenized by Stripe. Store minimal encrypted reference.
- **Email:** Postmark/SendGrid for verification, invites, password reset, check-in notifications.
- **Push notifications:** Use Firebase Cloud Messaging as gateway (supports APNs). No sensitive health data in payloads.

## 10. QA strategy (QA)
### 10.1 Scope & environments
- Test across iOS 17 (latest) + iOS 16 (n-1) devices (iPhone 14, iPhone SE). Web on Chrome, Safari, Edge (latest).
- Use staging Stripe/test keys, staged S3 bucket.

### 10.2 Test matrix highlights
1. **Onboarding flows:** Sign-up, email verify, password reset, invite acceptance (expired, revoked, duplicate email).
2. **Program builder:** Create/edit program, reorder days/exercises, template clone immutability, assignment generation.
3. **Workout logging:** Offline logging, sync conflict resolution, completion metrics, notes.
4. **Progress tracking:** Unit conversion accuracy, photo upload limits, permission enforcement (coach cannot see other coach’s clients).
5. **Check-ins:** Weekly limit, notification to coach, review feedback state.
6. **Messaging:** Text/image/audio send/receive, read receipts, long-poll fallback when offline.
7. **Payments:** Stripe onboarding, subscription success/failure, webhook retries (idempotency), UPI flows, cancelation.
8. **Dashboard:** Metric accuracy (mock data), zero-state guidance.

### 10.3 Automation & tooling
- Web: Playwright + TypeScript for regression of core coach flows.
- iOS: XCUITest covering Today view, workout logging, check-ins.
- API: Postman/Newman or Pact tests for contract validation, including Stripe webhook fixtures.
- Background jobs & webhooks covered via integration tests with localstack/minio + Stripe CLI fixtures.

### 10.4 Release readiness
- All FR acceptance criteria verified.
- No P0/P1 bugs open, P2 requires PM sign-off.
- Crash-free sessions ≥99% in TestFlight.
- Observability dashboards green (auth errors, webhook retries <1%).

## 11. Analytics & instrumentation (PM/SE)
Emit events with consistent schema (`actor_id`, `actor_role`, `entity_id`, `metadata` JSON).
- `coach_profile_completed`
- `client_invite_sent`
- `client_invite_accepted`
- `program_created`, `program_assigned`
- `workout_log_completed`
- `metric_logged`
- `progress_photo_uploaded`
- `check_in_submitted`
- `check_in_reviewed`
- `message_sent`
- `subscription_activated`, `subscription_canceled`
Wire events to Segment (or equivalent) → warehouse for KPI queries.

## 12. Delivery plan & Definition of Done (PM/QA)
1. Build order: Coach onboarding → client onboarding → programs/templates → assignments → client logging → progress tracking → check-ins → messaging → payments → dashboard.
2. Each story references FR ID in branch/PR (`feat/fr-5.2-workout-log`).
3. DoD checklist:
   - All acceptance criteria met.
   - Server-side authz/tenant checks verified + covered by tests.
   - Input validation + user-friendly errors.
   - Automated tests (unit + integration + UI where applicable).
   - Analytics events emitted and QA’d.
   - No secrets committed; config via env.
   - Manual verification on target surface (device or browser), recordings attached in PR.

## 13. Open decisions & assumptions log (PM)
| # | Topic | Current stance | Owner |
| --- | --- | --- | --- |
| 1 | Program scheduling | Sequential days from start date. Need confirmation before building weekday mode. | PM + SE |
| 2 | Single coach per client | Yes in MVP. Multi-coach requires major data changes; defer. | PM |
| 3 | Nutrition scope | Single daily target (coach-set). Store as numeric + unit for future macros. | PM + UX |
| 4 | Messaging transport | Start with polling (15s). Abstract to switch to WebSocket later. | SE |
| 5 | Backend stack | Default NestJS + TypeScript. Document if team chooses FastAPI. | SE lead |
| 6 | Auth provider | JWT in-house unless managed provider decision documented. | SE lead |
| 7 | Currencies/regions | USD default + currency per coach from Stripe. India coaches require INR + UPI. Confirm list before launch. | PM + Finance |

## 14. Reference docs
- `DEVELOPER_REQUIREMENTS.md` — source FRs
- `DESIGN_UX_SPECIFICATION.md` — visual + interaction details
- `DATA_DICTIONARY.xlsx` (future) — analytics schema
- Stripe integration guides, Apple HIG for iOS interactions

> This document is the implementation source of truth for Phase 1. Update it whenever Product/Engineering make a decision so junior developers always have the latest, unambiguous guidance.
