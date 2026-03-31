import Foundation

/// Persists folders as a single folders.json file in Application Support directory
final class FolderStorageService: FolderStorageServiceProtocol {

    static let shared = FolderStorageService()

    private let fileQueue = DispatchQueue(label: "com.paletto.folders", qos: .utility)
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var foldersURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent(Constants.Storage.foldersFileName)
    }

    init() {
        ensureDirectoryExists()
    }

    // MARK: - FolderStorageServiceProtocol

    func loadFolders() async throws -> [Folder] {
        try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { [self] in
                guard FileManager.default.fileExists(atPath: foldersURL.path) else {
                    // No file yet — initialize with empty array (first launch)
                    continuation.resume(returning: [])
                    return
                }

                do {
                    let data = try Data(contentsOf: foldersURL)
                    let folders = try decoder.decode([Folder].self, from: data)
                    continuation.resume(returning: folders)
                } catch {
                    // Corrupted file — log warning and return empty array
                    print("[FolderStorageService] ⚠️ Failed to load folders.json: \(error.localizedDescription). Initializing empty folder list.")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func saveFolder(_ folder: Folder) async throws {
        try await performFileOperation {
            var folders: [Folder] = []
            if FileManager.default.fileExists(atPath: self.foldersURL.path) {
                if let data = try? Data(contentsOf: self.foldersURL) {
                    folders = (try? self.decoder.decode([Folder].self, from: data)) ?? []
                }
            }
            // Replace if exists, append if new
            if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
                folders[idx] = folder
            } else {
                folders.append(folder)
            }
            let data = try self.encoder.encode(folders)
            try data.write(to: self.foldersURL, options: .atomic)
        }
    }

    func deleteFolder(id: UUID) async throws {
        try await performFileOperation {
            var folders: [Folder] = []
            if FileManager.default.fileExists(atPath: self.foldersURL.path) {
                if let data = try? Data(contentsOf: self.foldersURL) {
                    folders = (try? self.decoder.decode([Folder].self, from: data)) ?? []
                }
            }
            folders.removeAll { $0.id == id }
            let data = try self.encoder.encode(folders)
            try data.write(to: self.foldersURL, options: .atomic)
        }
    }

    func updateFolder(_ folder: Folder) async throws {
        try await saveFolder(folder)
    }

    // MARK: - Private

    private func loadFoldersInternal() {
        guard FileManager.default.fileExists(atPath: foldersURL.path) else { return }
        // Called synchronously within performFileOperation — file already checked by caller
    }

    private func ensureDirectoryExists() {
        let dir = foldersURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
    }

    private func performFileOperation(
        _ operation: @escaping () throws -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fileQueue.async {
                do {
                    try operation()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AppError.fileIOError(error.localizedDescription))
                }
            }
        }
    }
}
