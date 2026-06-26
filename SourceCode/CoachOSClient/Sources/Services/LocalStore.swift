//  LocalStore.swift
//  CoachOS — Services
//
//  CALLOUT: Offline-first persistence (NFR "Offline tolerance", FR-5.2). Workout
//  logs must survive app close and edits while offline. Production would use Core
//  Data/Realm; for a dependency-free, reviewable MVP this serializes Codable models
//  to JSON files in the app sandbox. Same Codable models as the API → trivial sync.

import Foundation

final class LocalStore {
    static let shared = LocalStore()
    private let dir: URL
    private let enc = JSONEncoder()
    private let dec = JSONDecoder()

    private init() {
        // CALLOUT: App-private Documents dir — sandboxed, not user-visible, survives relaunch.
        dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        enc.dateEncodingStrategy = .iso8601
        dec.dateDecodingStrategy = .iso8601
    }

    private func url(_ key: String) -> URL { dir.appendingPathComponent("\(key).json") }

    // CALLOUT: Generic save/load so any Codable list can be cached locally.
    func save<T: Codable>(_ value: T, key: String) {
        do { try enc.encode(value).write(to: url(key), options: .atomic) }
        catch { print("LocalStore save error:", error) }
    }
    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? dec.decode(T.self, from: data)
    }
    func clear() { try? FileManager.default.removeItem(at: dir) }
}
