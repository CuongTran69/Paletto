import SwiftUI
import Combine

/// ViewModel for palette detail screen
final class PaletteDetailViewModel: ObservableObject {

    @Published var palette: ColorPalette
    @Published var contrastMatrix: [[ContrastResult]] = []
    @Published var isSaving = false
    @Published var showExport = false
    @Published var showHarmony = false
    @Published var showShare = false
    @Published var harmonySourceColor: PaletteColor?

    private let contrastService: ContrastCheckerServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        palette: ColorPalette,
        contrastService: ContrastCheckerServiceProtocol = ContrastCheckerService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService()
    ) {
        self.palette = palette
        self.contrastService = contrastService
        self.storageService = storageService
        updateContrastMatrix()
    }

    // MARK: - Actions

    func autoAssignRoles() {
        palette.colors = contrastService.assignRoles(to: palette.colors)
        updateContrastMatrix()
        save()
    }

    func updateRole(for colorId: UUID, to role: ColorRole) {
        guard let index = palette.colors.firstIndex(where: { $0.id == colorId }) else { return }
        palette.colors[index].role = role
        save()
    }

    func suggestFix(foregroundIndex: Int, backgroundIndex: Int) -> PaletteColor? {
        guard palette.colors.indices.contains(foregroundIndex),
              palette.colors.indices.contains(backgroundIndex) else { return nil }
        return contrastService.suggestFix(
            for: palette.colors[foregroundIndex],
            against: palette.colors[backgroundIndex],
            targetLevel: .aa
        )
    }

    func applyFix(_ fixedColor: PaletteColor, at index: Int) {
        guard palette.colors.indices.contains(index) else { return }
        let role = palette.colors[index].role
        palette.colors[index] = fixedColor
        palette.colors[index].role = role
        updateContrastMatrix()
        save()
    }

    func updateName(_ name: String) {
        palette.name = name
        save()
    }

    func copyHex(_ hex: String) {
        UIPasteboard.general.string = hex
        if SettingsManager.shared.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func openHarmony(for color: PaletteColor) {
        harmonySourceColor = color
        showHarmony = true
    }

    // MARK: - Private

    private func updateContrastMatrix() {
        contrastMatrix = contrastService.contrastMatrix(for: palette.colors)
    }

    private func save() {
        isSaving = true
        storageService.update(palette)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isSaving = false
                },
                receiveValue: { }
            )
            .store(in: &cancellables)
    }
}

