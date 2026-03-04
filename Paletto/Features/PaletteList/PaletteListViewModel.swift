import SwiftUI
import Combine

/// ViewModel for the palette library screen
final class PaletteListViewModel: ObservableObject {

    @Published var palettes: [ColorPalette] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: PaletteStorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredPalettes: [ColorPalette] {
        if searchText.isEmpty { return palettes }
        return palettes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(storageService: PaletteStorageServiceProtocol = PaletteStorageService()) {
        self.storageService = storageService
    }

    func loadPalettes() {
        isLoading = true
        storageService.loadAll()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] palettes in
                    self?.palettes = palettes
                }
            )
            .store(in: &cancellables)
    }

    func deletePalette(at offsets: IndexSet) {
        let palettesToDelete = offsets.map { filteredPalettes[$0] }
        for palette in palettesToDelete {
            storageService.delete(id: palette.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] in
                        self?.palettes.removeAll { $0.id == palette.id }
                    }
                )
                .store(in: &cancellables)
        }
    }

    func deletePalette(_ palette: ColorPalette) {
        storageService.delete(id: palette.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in
                    self?.palettes.removeAll { $0.id == palette.id }
                }
            )
            .store(in: &cancellables)
    }
}

