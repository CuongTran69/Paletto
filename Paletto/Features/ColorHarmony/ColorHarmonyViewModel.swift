import SwiftUI
import Combine

/// ViewModel for the color harmony generator
final class ColorHarmonyViewModel: ObservableObject {

    @Published var sourceColor: PaletteColor
    @Published var selectedType: HarmonyType = .complementary
    @Published var harmonyColors: [PaletteColor] = []
    @Published var showSaveAlert = false

    private let harmonyService: ColorHarmonyServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        sourceColor: PaletteColor,
        harmonyService: ColorHarmonyServiceProtocol = ColorHarmonyService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService()
    ) {
        self.sourceColor = sourceColor
        self.harmonyService = harmonyService
        self.storageService = storageService
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
        if SettingsManager.shared.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func savePalette(name: String) -> AnyPublisher<ColorPalette, AppError> {
        let palette = ColorPalette(
            name: name.isEmpty ? L10n.harmonySaveDefault.localized : name,
            colors: harmonyColors
        )
        return storageService.save(palette)
            .map { palette }
            .eraseToAnyPublisher()
    }
}

