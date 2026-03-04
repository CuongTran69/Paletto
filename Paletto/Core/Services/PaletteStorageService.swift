import Foundation
import Combine

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

    func save(_ palette: ColorPalette) -> AnyPublisher<Void, AppError> {
        performFileOperation { [self] in
            let data = try encoder.encode(palette)
            let url = fileURL(for: palette.id)
            try data.write(to: url, options: .atomic)
        }
    }

    func loadAll() -> AnyPublisher<[ColorPalette], AppError> {
        Future<[ColorPalette], AppError> { [self] promise in
            fileQueue.async { [self] in
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: palettesDirectory,
                        includingPropertiesForKeys: nil
                    ).filter { $0.pathExtension == "json" }

                    let palettes = files.compactMap { url -> ColorPalette? in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        return try? decoder.decode(ColorPalette.self, from: data)
                    }
                    .sorted { $0.createdAt > $1.createdAt }

                    DispatchQueue.main.async { promise(.success(palettes)) }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.fileIOError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func load(id: UUID) -> AnyPublisher<ColorPalette?, AppError> {
        Future<ColorPalette?, AppError> { [self] promise in
            fileQueue.async { [self] in
                let url = fileURL(for: id)
                guard FileManager.default.fileExists(atPath: url.path) else {
                    DispatchQueue.main.async { promise(.success(nil)) }
                    return
                }
                do {
                    let data = try Data(contentsOf: url)
                    let palette = try decoder.decode(ColorPalette.self, from: data)
                    DispatchQueue.main.async { promise(.success(palette)) }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.fileIOError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func delete(id: UUID) -> AnyPublisher<Void, AppError> {
        performFileOperation { [self] in
            let url = fileURL(for: id)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    func update(_ palette: ColorPalette) -> AnyPublisher<Void, AppError> {
        var updated = palette
        updated.updatedAt = Date()
        return save(updated)
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
    ) -> AnyPublisher<Void, AppError> {
        Future<Void, AppError> { [self] promise in
            fileQueue.async {
                do {
                    try operation()
                    DispatchQueue.main.async { promise(.success(())) }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.fileIOError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

