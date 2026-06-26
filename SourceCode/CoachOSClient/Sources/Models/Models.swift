//  Models.swift
//  CoachOS — Models
//
//  CALLOUT: Client-side domain models. These mirror the data model in MVP.md §6
//  and DEVELOPER_REQUIREMENTS §9 (UUID ids, tenant fields). They are Codable so
//  the same types serialize to the local offline store AND to the future REST API
//  — one contract, no duplicate DTOs. Only the CLIENT-relevant subset is modeled
//  richly; coach-only entities are referenced by id.

import Foundation

// MARK: - Identity
enum Role: String, Codable { case coach, client }

// CALLOUT: The authenticated user. `unitPref` drives all weight/height display.
struct User: Codable, Identifiable, Equatable {
    let id: UUID
    var role: Role
    var name: String
    var email: String
    var photoURL: String?
    var timezone: String
    var unitPref: UnitPreference
    var emailVerifiedAt: Date?
}

// CALLOUT: Client intake profile (FR-2). Biometrics stored in base metric units.
struct ClientProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var userId: UUID
    var coachId: UUID         // tenant link — a client belongs to exactly one coach (MVP open Q2 default)
    var goal: String
    var dob: Date
    var heightCm: Double
    var startWeightKg: Double
    var status: ClientStatus
}
enum ClientStatus: String, Codable { case invited, active, inactive }

// CALLOUT: Minimal coach card shown to the client (read-only on iOS).
struct CoachSummary: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var photoURL: String?
    var specialties: [String]
}

// MARK: - Programs & assignment (read side for client)
struct Exercise: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var muscleGroup: String
    var demoURL: String?
}

// CALLOUT: A prescribed exercise within a day. `repsLower/Upper` model the rep
// RANGE the spec allows (e.g. 8–12). `targetLoadKg` is the coach's prescription;
// the client logs ACTUALS separately in SetLog.
struct ProgramExercise: Codable, Identifiable, Equatable {
    let id: UUID
    var exercise: Exercise
    var orderIndex: Int
    var sets: Int
    var repsLower: Int
    var repsUpper: Int
    var targetLoadKg: Double?
    var restSeconds: Int?
    var tempo: String?
    var notes: String?
    var repsText: String { repsLower == repsUpper ? "\(repsLower)" : "\(repsLower)–\(repsUpper)" }
}

struct WorkoutDay: Codable, Identifiable, Equatable {
    let id: UUID
    var orderIndex: Int
    var label: String          // "Day 1 – Push"
    var exercises: [ProgramExercise]
    var isRest: Bool           // explicit rest day (FR-4 scheduling model)
}

// MARK: - Execution data (the client writes these)
// CALLOUT: One workout log per scheduled date. Created ahead of time when an
// assignment starts (FR-5). `completedAt` set on completion → drives compliance.
struct WorkoutLog: Codable, Identifiable, Equatable {
    let id: UUID
    var assignmentId: UUID
    var clientId: UUID
    var scheduledDate: Date
    var dayLabel: String
    var isRest: Bool
    var setLogs: [SetLog]
    var completedAt: Date?
    var note: String?
    var dirty: Bool = true      // CALLOUT: offline sync flag — true = not yet synced to server
}

// CALLOUT: Per-set actuals the client enters mid-workout (FR-5.2).
struct SetLog: Codable, Identifiable, Equatable {
    let id: UUID
    var programExerciseId: UUID
    var exerciseName: String
    var setIndex: Int
    var prescribedReps: String
    var targetLoadKg: Double?
    var actualReps: Int?
    var actualLoadKg: Double?
    var completed: Bool
}

// MARK: - Progress (FR-6)
struct MetricEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var clientId: UUID
    var type: String            // "weight"
    var valueKg: Double         // stored base unit
    var recordedOn: Date
}
struct ProgressPhoto: Codable, Identifiable, Equatable {
    let id: UUID
    var clientId: UUID
    var localImageName: String  // CALLOUT: mock stores a local asset name; prod stores an S3 key + signed URL
    var takenOn: Date
}

// MARK: - Check-ins (FR-7)
// CALLOUT: `weekOf` is the ISO-week anchor used to PREVENT duplicate submissions
// in the same week (acceptance criterion in FR-7.1).
struct CheckIn: Codable, Identifiable, Equatable {
    let id: UUID
    var clientId: UUID
    var weekOf: Date
    var weightKg: Double
    var ratings: Ratings        // 1–5 scales
    var notes: String
    var status: CheckInStatus
    var coachFeedback: String?
    var reviewedAt: Date?
}
struct Ratings: Codable, Equatable {
    var energy: Int
    var sleep: Int
    var adherence: Int
}
enum CheckInStatus: String, Codable { case submitted, reviewed }

// MARK: - Messaging (FR-8)
enum MessageType: String, Codable { case text, image, voice }
struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    var conversationId: UUID
    var senderId: UUID
    var type: MessageType
    var body: String
    var mediaName: String?
    var sentAt: Date
    var readAt: Date?           // per-recipient read receipt
}
struct Conversation: Codable, Identifiable, Equatable {
    let id: UUID
    var coachId: UUID
    var clientId: UUID
    var lastMessageAt: Date?
}

// MARK: - Billing (FR-9)
// CALLOUT: Subscription state is SERVER-authoritative (driven by Stripe webhooks).
// The client only READS this; it never assumes success locally.
enum SubscriptionStatus: String, Codable { case none, active, pastDue = "past_due", canceled }
struct Subscription: Codable, Equatable {
    var status: SubscriptionStatus
    var priceCents: Int
    var currency: String
    var currentPeriodEnd: Date?
    var displayPrice: String {
        String(format: "%@%.2f / mo", currency == "INR" ? "₹" : "$", Double(priceCents) / 100)
    }
}

// MARK: - Today aggregate
// CALLOUT: The single payload the Today screen needs (FR-5.1). Bundling it mirrors
// the GET /client/today endpoint so one call paints the whole home screen.
struct TodayBundle: Codable, Equatable {
    var date: Date
    var workoutLog: WorkoutLog?     // nil = no program assigned yet
    var nutritionTarget: String?    // single coach-set value (MVP nutrition scope)
    var habits: [Habit]
    var checkInDue: Bool
}
struct Habit: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var done: Bool
}
