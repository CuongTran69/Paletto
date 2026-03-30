import SwiftUI

/// ViewModel for the palette library screen
final class PaletteListViewModel: ObservableObject {

    @Published var palettes: [ColorPalette] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Folder state
    @Published var folders: [Folder] = []
    @Published var selectedFolder: Folder?

    // MARK: - Tag state
    @Published var selectedTag: String?
    @Published var allTags: [String] = []

    // MARK: - Folder mutation state
    @Published var showCreateFolder = false
    @Published var showRenameFolder = false
    @Published var folderToRename: Folder?
    @Published var folderToDelete: Folder?
    @Published var showDeleteFolderConfirmation = false

    // MARK: - Filtered palettes

    var filteredPalettes: [ColorPalette] {
        var result = palettes

        // Filter by selected folder
        if let folder = selectedFolder {
            result = result.filter { folder.paletteIds.contains($0.id) }
        }

        // Filter by selected tag
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private let storageService: PaletteStorageServiceProtocol

    init(storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared) {
        self.storageService = storageService
    }

    // MARK: - Loading

    func loadPalettes() {
        if palettes.isEmpty { isLoading = true }
        Task { @MainActor in
            do {
                palettes = try await storageService.loadAll()
                folders = try await storageService.loadFolders()
                computeAllTags()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Folder operations

    func loadFolders() {
        Task { @MainActor in
            do {
                folders = try await storageService.loadFolders()
            } catch {
                // Silently fail — folder list just stays as-is
            }
        }
    }

    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= Constants.Folder.maxNameLength else { return }
        guard folders.count < Constants.Folder.maxCount else { return }
        guard !folders.contains(where: { $0.name == trimmed }) else { return }

        let folder = Folder(name: trimmed)
        Task { @MainActor in
            do {
                try await storageService.saveFolder(folder)
                folders.append(folder)
            } catch {
                // Silently fail
            }
        }
    }

    func renameFolder(_ folder: Folder, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= Constants.Folder.maxNameLength else { return }
        guard !folders.contains(where: { $0.name == trimmed && $0.id != folder.id }) else { return }

        var updated = folder
        updated.name = trimmed
        updated.updatedAt = Date()
        Task { @MainActor in
            do {
                try await storageService.updateFolder(updated)
                if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
                    folders[idx] = updated
                }
                // If currently selected folder was renamed, update selection
                if selectedFolder?.id == folder.id {
                    selectedFolder = updated
                }
            } catch {
                // Silently fail
            }
        }
    }

    func deleteFolder(_ folder: Folder) {
        Task { @MainActor in
            do {
                try await storageService.deleteFolder(id: folder.id)
                folders.removeAll { $0.id == folder.id }
                // If currently inside this folder, go back
                if selectedFolder?.id == folder.id {
                    selectedFolder = nil
                }
            } catch {
                // Silently fail
            }
        }
    }

    func addPaletteToFolder(paletteId: UUID, folderId: UUID?) {
        // Remove from all folders first (palette belongs to exactly one folder)
        for var folder in folders {
            if folder.paletteIds.contains(paletteId) {
                folder.paletteIds.removeAll { $0 == paletteId }
                folder.updatedAt = Date()
                Task { @MainActor in
                    try? await storageService.updateFolder(folder)
                }
                if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
                    folders[idx] = folder
                }
            }
        }

        // Add to target folder if not nil
        if let folderId {
            if let idx = folders.firstIndex(where: { $0.id == folderId }) {
                var folder = folders[idx]
                if !folder.paletteIds.contains(paletteId) {
                    folder.paletteIds.append(paletteId)
                    folder.updatedAt = Date()
                    Task { @MainActor in
                        try? await storageService.updateFolder(folder)
                    }
                    folders[idx] = folder
                }
            }
        }
    }

    // MARK: - Tag operations

    func addTagToPalette(paletteId: UUID, tag: String) {
        guard let idx = palettes.firstIndex(where: { $0.id == paletteId }) else { return }
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= Constants.Palette.maxTagLength else { return }
        guard !palettes[idx].tags.contains(trimmed) else { return }
        guard palettes[idx].tags.count < Constants.Palette.maxTagsPerPalette else { return }

        palettes[idx].tags.append(trimmed)
        palettes[idx].updatedAt = Date()

        Task { @MainActor in
            do {
                try await storageService.update(palettes[idx])
            } catch {
                // Silently fail
            }
        }

        computeAllTags()
    }

    func removeTagFromPalette(paletteId: UUID, tag: String) {
        guard let idx = palettes.firstIndex(where: { $0.id == paletteId }) else { return }
        palettes[idx].tags.removeAll { $0 == tag }
        palettes[idx].updatedAt = Date()

        Task { @MainActor in
            do {
                try await storageService.update(palettes[idx])
            } catch {
                // Silently fail
            }
        }

        computeAllTags()
    }

    // MARK: - Delete

    func deletePalette(at offsets: IndexSet) {
        let palettesToDelete = offsets.map { filteredPalettes[$0] }
        for palette in palettesToDelete {
            Task { @MainActor in
                do {
                    try await storageService.delete(id: palette.id)
                    palettes.removeAll { $0.id == palette.id }
                } catch {
                    // Silently fail — palette may already be deleted
                }
            }
        }
    }

    func deletePalette(_ palette: ColorPalette) {
        Task { @MainActor in
            do {
                try await storageService.delete(id: palette.id)
                palettes.removeAll { $0.id == palette.id }
            } catch {
                // Silently fail — palette may already be deleted
            }
        }
    }

    // MARK: - Private

    private func computeAllTags() {
        var tags = Set<String>()
        for palette in palettes {
            for tag in palette.tags {
                tags.insert(tag)
            }
        }
        allTags = tags.sorted()
    }
}
