import SwiftUI

/// ViewModel for the color harmony generator
final class ColorHarmonyViewModel: ObservableObject {

    @Published var sourceColor: PaletteColor
    @Published var selectedType: HarmonyType = .complementary
    @Published var harmonyColors: [PaletteColor] = []
    @Published var showSaveAlert = false

    private let harmonyService: ColorHarmonyServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    init(
        sourceColor: PaletteColor,
        harmonyService: ColorHarmonyServiceProtocol = ColorHarmonyService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService(),
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.sourceColor = sourceColor
        self.harmonyService = harmonyService
        self.storageService = storageService
        self.settingsManager = settingsManager
        generateHarmony()
    }

    func generateHarmony() {
        harmonyColors = harmonyService.generateHarmony(from: sourceColor, type: selectedType)
    }

    func selectType(_ type: HarmonyType) {
        selectedType = type
        generateHarmony()
    }

    func copyHex(_ hex: String) {
        UIPasteboard.general.string = hex
        if settingsManager.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func savePalette(name: String) async throws -> ColorPalette {
        let palette = ColorPalette(
            name: name.isEmpty ? L10n.harmonySaveDefault.localized : name,
            colors: harmonyColors
        )
        try await storageService.save(palette)
        return palette
    }
}

