import Foundation

/// Persists palettes as JSON files in Application Support directory
final class PaletteStorageService: PaletteStorageServiceProtocol {

    private let fileQueue = DispatchQueue(label: "com.paletto.storage", qos: .utility)
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

    private var palettesDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent(Constants.Storage.palettesDirectoryName)
    }

    init() {
        ensureDirectoryExists()
    }

    // MARK: - Public API

    func save(_ palette: ColorPalette) async throws {
        try await performFileOperation {
            let data = try self.encoder.encode(palette)
            let url = self.fileURL(for: palette.id)
            try data.write(to: url, options: .atomic)
        }
    }

    func loadAll() async throws -> [ColorPalette] {
        try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { [self] in
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: palettesDirectory,
                        includingPropertiesForKeys: nil
                    ).filter { $0.pathExtension == "json" }

                    let palettes = files.compactMap { url -> ColorPalette? in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        guard let palette = try? decoder.decode(ColorPalette.self, from: data) else { return nil }
                        return PaletteMigration.migrateIfNeeded(palette)
                    }
                    .sorted { $0.createdAt > $1.createdAt }

                    continuation.resume(returning: palettes)
                } catch {
                    continuation.resume(throwing: AppError.fileIOError(error.localizedDescription))
                }
            }
        }
    }

    func load(id: UUID) async throws -> ColorPalette? {
        try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { [self] in
                let url = fileURL(for: id)
                guard FileManager.default.fileExists(atPath: url.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    let data = try Data(contentsOf: url)
                    let palette = try decoder.decode(ColorPalette.self, from: data)
                    continuation.resume(returning: PaletteMigration.migrateIfNeeded(palette))
                } catch {
                    continuation.resume(throwing: AppError.fileIOError(error.localizedDescription))
                }
            }
        }
    }

    func delete(id: UUID) async throws {
        try await performFileOperation {
            let url = self.fileURL(for: id)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    func update(_ palette: ColorPalette) async throws {
        var updated = palette
        updated.updatedAt = Date()
        try await save(updated)
    }

    // MARK: - Private

    private func fileURL(for id: UUID) -> URL {
        palettesDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(
            at: palettesDirectory,
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

