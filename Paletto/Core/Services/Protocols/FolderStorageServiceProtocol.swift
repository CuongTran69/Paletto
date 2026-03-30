import Foundation

/// Protocol for persisting and retrieving folders
protocol FolderStorageServiceProtocol {
    func loadFolders() async throws -> [Folder]
    func saveFolder(_ folder: Folder) async throws
    func deleteFolder(id: UUID) async throws
    func updateFolder(_ folder: Folder) async throws
}
