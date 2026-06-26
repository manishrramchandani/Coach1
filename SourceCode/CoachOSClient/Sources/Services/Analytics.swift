//  Analytics.swift
//  CoachOS — Services
//
//  CALLOUT: Instruments the success-metric events from MVP §11 / DEV §13 from day
//  one. Events use the consistent schema (actor_id, actor_role, entity_id, metadata).
//  Mock build prints to console; production swaps `sink` for Segment/warehouse.
//  Emitting these is part of the Definition of Done (§DoD item 6).

import Foundation

enum AnalyticsEvent: String {
    case clientInviteAccepted = "client_invite_accepted"
    case workoutLogCompleted  = "workout_log_completed"   // → client Activation (first) + compliance
    case metricLogged         = "metric_logged"
    case progressPhotoUploaded = "progress_photo_uploaded"
    case checkInSubmitted     = "check_in_submitted"
    case messageSent          = "message_sent"
    case subscriptionActivated = "subscription_activated"
    case subscriptionCanceled = "subscription_canceled"
}

final class Analytics {
    static let shared = Analytics()
    private(set) var actorId: UUID?
    private(set) var actorRole: Role = .client

    func identify(_ user: User) { actorId = user.id; actorRole = user.role }

    // CALLOUT: One choke point for every event → guarantees consistent schema and
    // makes it trivial to validate in QA (analytics validation, QA.md).
    func track(_ event: AnalyticsEvent, entityId: UUID? = nil, metadata: [String: String] = [:]) {
        let payload: [String: Any] = [
            "event": event.rawValue,
            "actor_id": actorId?.uuidString ?? "anon",
            "actor_role": actorRole.rawValue,
            "entity_id": entityId?.uuidString ?? "",
            "metadata": metadata
        ]
        print("📊 ANALYTICS:", payload)   // sink → Segment in production
    }
}
