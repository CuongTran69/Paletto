import SwiftUI

/// ViewModel for palette comparison screen
final class PaletteComparisonViewModel: ObservableObject {

    @Published var palettes: [ColorPalette] = []
    @Published var selectedPalette1: ColorPalette?
    @Published var selectedPalette2: ColorPalette?
    @Published var comparisonResult: PaletteComparisonResult?
    @Published var isLoading = false

    private let comparisonService: PaletteComparisonServiceProtocol
    private let storageService: PaletteStorageServiceProtocol

    init(
        comparisonService: PaletteComparisonServiceProtocol = PaletteComparisonService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared
    ) {
        self.comparisonService = comparisonService
        self.storageService = storageService
    }

    func loadPalettes() {
        isLoading = true
        Task { @MainActor in
            do {
                palettes = try await storageService.loadAll()
            } catch {
                // Silently fail — empty list is shown
            }
            isLoading = false
        }
    }

    func selectPalette1(_ palette: ColorPalette) {
        selectedPalette1 = palette
        compareIfReady()
    }

    func selectPalette2(_ palette: ColorPalette) {
        selectedPalette2 = palette
        compareIfReady()
    }

    func swapPalettes() {
        let temp = selectedPalette1
        selectedPalette1 = selectedPalette2
        selectedPalette2 = temp
        compareIfReady()
    }

    private func compareIfReady() {
        guard let p1 = selectedPalette1, let p2 = selectedPalette2 else {
            comparisonResult = nil
            return
        }
        comparisonResult = comparisonService.compare(p1, with: p2)
    }

    /// Palettes available for second picker (exclude first selection)
    var availableForSecond: [ColorPalette] {
        guard let first = selectedPalette1 else { return palettes }
        return palettes.filter { $0.id != first.id }
    }
}

