import SwiftUI

/// ViewModel for the palette library screen
final class PaletteListViewModel: ObservableObject {

    @Published var palettes: [ColorPalette] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: PaletteStorageServiceProtocol

    var filteredPalettes: [ColorPalette] {
        if searchText.isEmpty { return palettes }
        return palettes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared) {
        self.storageService = storageService
    }

    func loadPalettes() {
        if palettes.isEmpty { isLoading = true }
        Task { @MainActor in
            do {
                palettes = try await storageService.loadAll()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

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
}

