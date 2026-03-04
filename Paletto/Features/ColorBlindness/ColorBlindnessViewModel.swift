import SwiftUI

/// ViewModel for color blindness simulator
final class ColorBlindnessViewModel: ObservableObject {

    @Published var selectedType: ColorBlindnessType = .protanopia
    @Published var simulationResult: PaletteSimulationResult?

    let palette: ColorPalette
    private let service: ColorBlindnessServiceProtocol

    init(
        palette: ColorPalette,
        service: ColorBlindnessServiceProtocol = ColorBlindnessService()
    ) {
        self.palette = palette
        self.service = service
        runSimulation()
    }

    func selectType(_ type: ColorBlindnessType) {
        selectedType = type
        runSimulation()
    }

    var warningMessage: String? {
        guard let result = simulationResult, selectedType != .normal else { return nil }
        let count = result.confusablePairs.count
        let total = palette.colors.count * (palette.colors.count - 1) / 2
        if count > 0 {
            return L10n.blindnessWarning.localized(args: [
                "count": "\(count)",
                "total": "\(total)",
                "type": selectedType.displayName
            ])
        } else {
            return L10n.blindnessNoIssues.localized(args: [
                "type": selectedType.displayName
            ])
        }
    }

    var hasIssues: Bool {
        guard let result = simulationResult else { return false }
        return !result.confusablePairs.isEmpty
    }

    private func runSimulation() {
        simulationResult = service.simulatePalette(palette, type: selectedType)
    }
}

