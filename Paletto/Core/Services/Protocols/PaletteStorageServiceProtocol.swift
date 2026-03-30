import Foundation

/// Protocol for persisting and retrieving palettes
protocol PaletteStorageServiceProtocol {
    func save(_ palette: ColorPalette) async throws -> Void
    func loadAll() async throws -> [ColorPalette]
    func load(id: UUID) async throws -> ColorPalette?
    func delete(id: UUID) async throws -> Void
    func update(_ palette: ColorPalette) async throws -> Void

    // MARK: - Folder operations (delegated to FolderStorageService)

    func loadFolders() async throws -> [Folder]
    func saveFolder(_ folder: Folder) async throws
    func deleteFolder(id: UUID) async throws
    func updateFolder(_ folder: Folder) async throws
}

