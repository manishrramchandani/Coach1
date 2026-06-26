//  APIService.swift
//  CoachOS — Services
//
//  CALLOUT: THE SEAM. This protocol is the exact contract the iOS client expects
//  from the backend (mirrors the REST surface in DEVELOPER_REQUIREMENTS §10).
//  Today it's fulfilled by MockAPIService (in-memory) so the app runs with no
//  server. To go live, implement `LiveAPIService` against the NestJS/FastAPI API
//  — NO view or view-model changes required. This is the "wrap in a service layer"
//  guidance from MVP §FR-8 applied to the whole app.

import Foundation

protocol APIService {
    // Auth / onboarding (FR-1, FR-2)
    func acceptInvite(token: String, password: String, intake: IntakePayload) async throws -> Session

    // Today + workout (FR-5)
    func fetchToday() async throws -> TodayBundle
    func saveWorkoutLog(_ log: WorkoutLog) async throws            // upsert (offline sync target)
    func completeWorkout(_ logId: UUID, note: String?) async throws

    // Progress (FR-6)
    func fetchMetrics() async throws -> [MetricEntry]
    func logWeight(kg: Double, on date: Date) async throws -> MetricEntry
    func fetchPhotos() async throws -> [ProgressPhoto]
    func uploadPhoto(localName: String, takenOn: Date) async throws -> ProgressPhoto

    // Check-ins (FR-7)
    func fetchCheckIns() async throws -> [CheckIn]
    func submitCheckIn(weightKg: Double, ratings: Ratings, notes: String) async throws -> CheckIn

    // Messaging (FR-8)
    func fetchMessages() async throws -> (Conversation, [Message])
    func sendMessage(_ body: String) async throws -> Message
    func markRead() async throws

    // Billing (FR-9) — client only reads/initiates; Stripe owns the truth
    func fetchSubscription() async throws -> Subscription
    func beginCheckoutURL() async throws -> URL     // hosted Stripe flow, never a custom card form
    func cancelSubscription() async throws -> Subscription

    var currentUser: User? { get }
    var coach: CoachSummary? { get }
}

// CALLOUT: Intake fields collected on the iOS onboarding screen (FR-2.2).
struct IntakePayload {
    var goal: String
    var dob: Date
    var heightValue: Double
    var startWeightValue: Double
    var unitPref: UnitPreference
}

struct Session { var user: User; var coach: CoachSummary }

// CALLOUT: User-facing error type. Keeps messages non-leaky (NFR/§DoD) — no stack
// traces or server internals ever shown to the user.
enum APIError: LocalizedError {
    case offline, duplicateCheckIn, invalidInvite, generic(String)
    var errorDescription: String? {
        switch self {
        case .offline: return "You're offline. We saved this and will sync when you're back."
        case .duplicateCheckIn: return "You've already checked in this week."
        case .invalidInvite: return "This invite link is invalid or expired. Ask your coach to resend it."
        case .generic(let m): return m
        }
    }
}
