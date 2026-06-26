//  MockAPIService.swift
//  CoachOS — Services
//
//  CALLOUT: In-memory implementation of APIService so the app is FULLY RUNNABLE
//  with zero backend. It seeds a realistic scenario (coach "Maya", client "Sam",
//  a 4-day program assigned this week) so every screen has data to show. It also
//  enforces the same business RULES the real backend must (e.g. one check-in per
//  ISO week) so QA can validate behavior here before the live API exists.

import Foundation

@MainActor
final class MockAPIService: APIService {
    // Seeded identities
    private(set) var currentUser: User?
    private(set) var coach: CoachSummary?

    // In-memory tenant data
    private var clientId = UUID()
    private var assignmentId = UUID()
    private var todayLog: WorkoutLog?
    private var metrics: [MetricEntry] = []
    private var photos: [ProgressPhoto] = []
    private var checkIns: [CheckIn] = []
    private var conversation: Conversation!
    private var messages: [Message] = []
    private var subscription = Subscription(status: .active, priceCents: 12000, currency: "USD",
                                            currentPeriodEnd: Calendar.current.date(byAdding: .day, value: 21, to: Date()))
    private var habits: [Habit] = []

    init() { seed() }

    // MARK: - Seed
    // CALLOUT: Builds a believable demo dataset. Mirrors the happy path in MVP §2.2.
    private func seed() {
        let coachId = UUID()
        coach = CoachSummary(id: coachId, name: "Maya Chen", photoURL: nil,
                             specialties: ["Fat loss", "Strength"])
        currentUser = User(id: UUID(), role: .client, name: "Sam Rivera",
                           email: "sam@example.com", photoURL: nil,
                           timezone: TimeZone.current.identifier, unitPref: .metric,
                           emailVerifiedAt: Date())
        Analytics.shared.identify(currentUser!)

        // Build today's prescribed workout (Push day)
        func pe(_ name: String, _ group: String, sets: Int, lo: Int, hi: Int, load: Double?) -> ProgramExercise {
            ProgramExercise(id: UUID(), exercise: Exercise(id: UUID(), name: name, muscleGroup: group, demoURL: nil),
                            orderIndex: 0, sets: sets, repsLower: lo, repsUpper: hi,
                            targetLoadKg: load, restSeconds: 90, tempo: nil, notes: nil)
        }
        let prescribed = [
            pe("Barbell Bench Press", "Chest", sets: 4, lo: 6, hi: 8, load: 60),
            pe("Overhead Press", "Shoulders", sets: 3, lo: 8, hi: 10, load: 35),
            pe("Incline Dumbbell Press", "Chest", sets: 3, lo: 10, hi: 12, load: 22)
        ]
        // CALLOUT: SetLogs are created ahead of time (FR-5.2) so the client only fills actuals.
        var sets: [SetLog] = []
        for ex in prescribed {
            for s in 1...ex.sets {
                sets.append(SetLog(id: UUID(), programExerciseId: ex.id, exerciseName: ex.exercise.name,
                                   setIndex: s, prescribedReps: ex.repsText, targetLoadKg: ex.targetLoadKg,
                                   actualReps: nil, actualLoadKg: nil, completed: false))
            }
        }
        todayLog = WorkoutLog(id: UUID(), assignmentId: assignmentId, clientId: clientId,
                              scheduledDate: Date(), dayLabel: "Day 1 – Push", isRest: false,
                              setLogs: sets, completedAt: nil, note: nil, dirty: false)

        habits = [Habit(id: UUID(), text: "10k steps", done: false),
                  Habit(id: UUID(), text: "Drink 3L water", done: true),
                  Habit(id: UUID(), text: "8h sleep", done: false)]

        // Weight history for the trend chart (FR-6)
        for i in stride(from: 42, through: 0, by: -7) {
            let d = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            metrics.append(MetricEntry(id: UUID(), clientId: clientId, type: "weight",
                                       valueKg: 78.0 - Double(42 - i) * 0.08, recordedOn: d))
        }

        conversation = Conversation(id: UUID(), coachId: coachId, clientId: clientId, lastMessageAt: Date())
        messages = [
            Message(id: UUID(), conversationId: conversation.id, senderId: coachId, type: .text,
                    body: "Welcome Sam! Your first week is live. Smash that bench 💪", mediaName: nil,
                    sentAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, readAt: Date())
        ]
    }

    // MARK: - Auth
    func acceptInvite(token: String, password: String, intake: IntakePayload) async throws -> Session {
        try await delay()
        // CALLOUT: Validate invite token shape (real API checks expiry/uniqueness, FR-2.1).
        guard !token.isEmpty else { throw APIError.invalidInvite }
        var u = currentUser!
        u.unitPref = intake.unitPref
        currentUser = u
        Analytics.shared.identify(u)
        Analytics.shared.track(.clientInviteAccepted, entityId: u.id)
        return Session(user: u, coach: coach!)
    }

    // MARK: - Today / workout
    func fetchToday() async throws -> TodayBundle {
        try await delay()
        return TodayBundle(date: Date(), workoutLog: todayLog, nutritionTarget: "2,100 kcal",
                           habits: habits, checkInDue: !hasCheckInThisWeek())
    }
    func saveWorkoutLog(_ log: WorkoutLog) async throws { try await delay(); todayLog = log }
    func completeWorkout(_ logId: UUID, note: String?) async throws {
        try await delay()
        todayLog?.completedAt = Date(); todayLog?.note = note
        // CALLOUT: Completion emits the compliance event (drives §13 metrics).
        Analytics.shared.track(.workoutLogCompleted, entityId: logId)
    }

    // MARK: - Progress
    func fetchMetrics() async throws -> [MetricEntry] { try await delay(); return metrics.sorted { $0.recordedOn < $1.recordedOn } }
    func logWeight(kg: Double, on date: Date) async throws -> MetricEntry {
        try await delay()
        let m = MetricEntry(id: UUID(), clientId: clientId, type: "weight", valueKg: kg, recordedOn: date)
        metrics.append(m); Analytics.shared.track(.metricLogged, entityId: m.id)
        return m
    }
    func fetchPhotos() async throws -> [ProgressPhoto] { try await delay(); return photos.sorted { $0.takenOn > $1.takenOn } }
    func uploadPhoto(localName: String, takenOn: Date) async throws -> ProgressPhoto {
        try await delay()
        let p = ProgressPhoto(id: UUID(), clientId: clientId, localImageName: localName, takenOn: takenOn)
        photos.append(p); Analytics.shared.track(.progressPhotoUploaded, entityId: p.id)
        return p
    }

    // MARK: - Check-ins
    func fetchCheckIns() async throws -> [CheckIn] { try await delay(); return checkIns.sorted { $0.weekOf > $1.weekOf } }
    func submitCheckIn(weightKg: Double, ratings: Ratings, notes: String) async throws -> CheckIn {
        try await delay()
        // CALLOUT: Enforce one-per-ISO-week rule (FR-7.1 acceptance criterion).
        guard !hasCheckInThisWeek() else { throw APIError.duplicateCheckIn }
        let c = CheckIn(id: UUID(), clientId: clientId, weekOf: startOfISOWeek(Date()),
                        weightKg: weightKg, ratings: ratings, notes: notes,
                        status: .submitted, coachFeedback: nil, reviewedAt: nil)
        checkIns.append(c); Analytics.shared.track(.checkInSubmitted, entityId: c.id)
        return c
    }

    // MARK: - Messaging
    func fetchMessages() async throws -> (Conversation, [Message]) {
        try await delay(); return (conversation, messages.sorted { $0.sentAt < $1.sentAt })
    }
    func sendMessage(_ body: String) async throws -> Message {
        try await delay()
        let m = Message(id: UUID(), conversationId: conversation.id, senderId: currentUser!.id,
                        type: .text, body: body, mediaName: nil, sentAt: Date(), readAt: nil)
        messages.append(m); Analytics.shared.track(.messageSent, entityId: m.id)
        return m
    }
    func markRead() async throws {
        // CALLOUT: Stamp read_at on inbound messages (FR-8 read receipts).
        for i in messages.indices where messages[i].senderId != currentUser!.id && messages[i].readAt == nil {
            messages[i].readAt = Date()
        }
    }

    // MARK: - Billing
    func fetchSubscription() async throws -> Subscription { try await delay(); return subscription }
    func beginCheckoutURL() async throws -> URL {
        // CALLOUT: Returns the HOSTED Stripe URL. iOS never renders a card form (FR-9.2).
        URL(string: "https://checkout.stripe.com/demo-session")!
    }
    func cancelSubscription() async throws -> Subscription {
        try await delay()
        // Access continues to period end (FR-9.2); status flips to canceled.
        subscription.status = .canceled
        Analytics.shared.track(.subscriptionCanceled)
        return subscription
    }

    // MARK: - Helpers
    private func delay() async throws { try await Task.sleep(nanoseconds: 250_000_000) }  // simulate network
    private func startOfISOWeek(_ date: Date) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    private func hasCheckInThisWeek() -> Bool {
        let w = startOfISOWeek(Date())
        return checkIns.contains { Calendar.current.isDate($0.weekOf, inSameDayAs: w) }
    }
}
