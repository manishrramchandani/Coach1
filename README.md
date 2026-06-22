# CoachOS — Product Documentation

> The operating system for fitness coaches. One platform for programs, payments, tracking, accountability, and messaging — replacing the 5–7 tools coaches juggle today.

This repository holds the Phase 1 **MVP** specification, split by audience.

## Documents

| Document | For | What it covers |
|---|---|---|
| [`DEVELOPER_REQUIREMENTS.md`](./DEVELOPER_REQUIREMENTS.md) | Junior Developers | PRD + engineering spec: scope, roles, functional requirements (user stories + acceptance criteria), data model, API surface, architecture, Definition of Done. |
| [`DESIGN_UX_SPECIFICATION.md`](./DESIGN_UX_SPECIFICATION.md) | Junior Designers | Personas, user flows, screen-by-screen specs with states, design system, accessibility, deliverables. |

Both documents share the same **Functional Requirement IDs (FR-x.y)** and the same scope, so a designer and a developer can point to the exact same feature.

## How the IDs work

Reference the FR ID in branches, commits, PRs, and design files:

```
feat(FR-3.2): program builder — add/reorder workout days
```

## Scope at a glance

**Phase 1 (this repo):** coach onboarding → client onboarding → program assignment → workout tracking → progress tracking → payments → messaging.
**Goal:** 10 coaches managing 100 clients.

Later phases (marketplace, AI program builder, accountability engine, community) are documented as future scope inside the developer doc and are intentionally out of scope for now.

## Before you start

Skim the **Open Questions** section at the end of each document first — those are the decisions most likely to need Product input (e.g. the workout-scheduling model and how much nutrition to include in the MVP). Items marked `[ASSUMPTION]` are Product decisions made to remove ambiguity; question them before building, don't silently change them.

---

*"CoachOS" is a working product name — find-and-replace across files to rename.*
