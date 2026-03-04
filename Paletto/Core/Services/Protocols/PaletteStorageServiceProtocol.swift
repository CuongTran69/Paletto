import Foundation
import Combine

/// Protocol for persisting and retrieving palettes
protocol PaletteStorageServiceProtocol {
    /// Save a palette to storage
    func save(_ palette: ColorPalette) -> AnyPublisher<Void, AppError>

    /// Load all saved palettes
    func loadAll() -> AnyPublisher<[ColorPalette], AppError>

    /// Load a single palette by ID
    func load(id: UUID) -> AnyPublisher<ColorPalette?, AppError>

    /// Delete a palette by ID
    func delete(id: UUID) -> AnyPublisher<Void, AppError>

    /// Update an existing palette
    func update(_ palette: ColorPalette) -> AnyPublisher<Void, AppError>
}

