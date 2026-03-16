import SwiftUI

/// ViewModel for palette detail screen
final class PaletteDetailViewModel: ObservableObject {

    @Published var palette: ColorPalette
    @Published var contrastMatrix: [[ContrastResult]] = []
    @Published var isSaving = false
    @Published var showExport = false
    @Published var showHarmony = false
    @Published var showShare = false
    @Published var showWidgetConfirmation = false
    @Published var harmonySourceColor: PaletteColor?

    private let contrastService: ContrastCheckerServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    init(
        palette: ColorPalette,
        contrastService: ContrastCheckerServiceProtocol = ContrastCheckerService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService(),
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.palette = palette
        self.contrastService = contrastService
        self.storageService = storageService
        self.settingsManager = settingsManager
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
        updateContrastForColor(at: index)
        save()
    }

    func updateName(_ name: String) {
        palette.name = name
        save()
    }

    func copyHex(_ hex: String) {
        UIPasteboard.general.string = hex
        if settingsManager.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func openHarmony(for color: PaletteColor) {
        harmonySourceColor = color
        showHarmony = true
    }

    func setAsWidget() {
        SharedDataService.shared.setWidgetPalette(palette)
        showWidgetConfirmation = true
        if settingsManager.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Private

    private func updateContrastMatrix() {
        contrastMatrix = contrastService.contrastMatrix(for: palette.colors)
    }

    private func updateContrastForColor(at index: Int) {
        contrastMatrix = contrastService.updateContrastMatrix(contrastMatrix, forColorAt: index, in: palette.colors)
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            do {
                try await storageService.update(palette)
            } catch {
                // Silently fail — UI already shows the updated state
            }
            isSaving = false
        }
    }
}

