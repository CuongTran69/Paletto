import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Manages Firebase initialization, authentication, and cloud synchronization
@MainActor
final class FirebaseService: ObservableObject {

    static let shared = FirebaseService()

    @Published private(set) var isConfigured: Bool = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var isSyncing: Bool = false
    @Published var lastSyncError: String?

    private var db: Firestore? {
        guard isConfigured else { return nil }
        return Firestore.firestore()
    }

    private init() {}

    // MARK: - Configuration

    /// Configures Firebase using GoogleService-Info.plist if available in the main bundle
    func configure() {
        guard !isConfigured else { return }

        // Check for GoogleService-Info.plist in bundle
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: plistPath) else {
            print("[FirebaseService] ⚠️ GoogleService-Info.plist not found in bundle. Firebase will not be initialized.")
            return
        }

        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        isConfigured = true
        let projectId = FirebaseApp.app()?.options.projectID ?? "unknown"
        print("[FirebaseService] ✅ Firebase configured successfully with project: \(projectId)")

        // Check existing auth state
        if let user = Auth.auth().currentUser {
            self.currentUserId = user.uid
            print("[FirebaseService] Current user: \(user.uid)")
        } else {
            // Sign in anonymously in background for seamless cloud sync
            Task {
                try? await self.signInAnonymously()
            }
        }
    }

    // MARK: - Authentication

    /// Sign in anonymously to identify user's palettes securely in Firestore
    @discardableResult
    func signInAnonymously() async throws -> String {
        guard isConfigured else {
            throw AppError.unknown("Firebase is not configured")
        }

        let result = try await Auth.auth().signInAnonymously()
        let uid = result.user.uid
        self.currentUserId = uid
        print("[FirebaseService] ✅ Signed in anonymously with UID: \(uid)")
        return uid
    }

    // MARK: - Firestore Cloud Sync

    /// Sync a single palette to Firestore under users/{userId}/palettes/{paletteId}
    func syncPalette(_ palette: ColorPalette) async throws {
        guard isConfigured, let db = db else {
            print("[FirebaseService] ⚠️ Skip sync: Firebase not configured")
            return
        }

        let uid: String
        if let currentUserId = currentUserId {
            uid = currentUserId
        } else {
            uid = (try? await signInAnonymously()) ?? "anonymous"
        }

        let data: [String: Any] = [
            "id": palette.id.uuidString,
            "name": palette.name,
            "colors": palette.colors.map { color in
                [
                    "id": color.id.uuidString,
                    "hex": color.hex,
                    "red": color.red,
                    "green": color.green,
                    "blue": color.blue,
                    "alpha": color.alpha,
                    "role": color.role?.rawValue as Any
                ]
            },
            "tags": palette.tags,
            "version": palette.version,
            "updatedAt": Timestamp(date: palette.updatedAt),
            "createdAt": Timestamp(date: palette.createdAt)
        ]

        try await db.collection("users").document(uid).collection("palettes").document(palette.id.uuidString).setData(data, merge: true)
        print("[FirebaseService] ✅ Synced palette '\(palette.name)' (\(palette.id)) to cloud")
    }

    /// Fetch all cloud palettes for the current user
    func fetchCloudPalettes() async throws -> [ColorPalette] {
        guard isConfigured, let db = db, let uid = currentUserId else {
            return []
        }

        isSyncing = true
        defer { isSyncing = false }

        let snapshot = try await db.collection("users").document(uid).collection("palettes").getDocuments()

        var results: [ColorPalette] = []
        for doc in snapshot.documents {
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let idString = data["id"] as? String,
                  let uuid = UUID(uuidString: idString) else { continue }

            let tags = data["tags"] as? [String] ?? []
            let version = data["version"] as? Int ?? 2
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

            var colors: [PaletteColor] = []
            if let colorDicts = data["colors"] as? [[String: Any]] {
                for c in colorDicts {
                    let r = c["red"] as? CGFloat ?? 0
                    let g = c["green"] as? CGFloat ?? 0
                    let b = c["blue"] as? CGFloat ?? 0
                    let a = c["alpha"] as? CGFloat ?? 1.0
                    let roleStr = c["role"] as? String
                    let role = roleStr.flatMap { ColorRole(rawValue: $0) }
                    let colorId = (c["id"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()

                    colors.append(PaletteColor(id: colorId, red: r, green: g, blue: b, alpha: a, role: role))
                }
            }

            results.append(ColorPalette(
                id: uuid,
                name: name,
                colors: colors,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                tags: tags
            ))
        }

        return results
    }

    /// Delete palette from Firestore
    func deleteCloudPalette(id: UUID) async throws {
        guard isConfigured, let db = db, let uid = currentUserId else { return }
        try await db.collection("users").document(uid).collection("palettes").document(id.uuidString).delete()
        print("[FirebaseService] ✅ Deleted palette \(id) from cloud")
    }
}

