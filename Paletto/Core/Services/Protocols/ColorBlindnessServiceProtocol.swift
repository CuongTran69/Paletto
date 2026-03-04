import Foundation

/// Result of simulating a single color under color blindness
struct SimulatedColor: Identifiable {
    let id = UUID()
    let original: PaletteColor
    let simulated: PaletteColor
    let deltaE: CGFloat
}

/// A pair of colors that become indistinguishable under color blindness
struct ConfusablePair: Identifiable {
    let id = UUID()
    let index1: Int
    let index2: Int
    let color1: PaletteColor
    let color2: PaletteColor
    let simulatedDeltaE: CGFloat
}

/// Result of simulating an entire palette
struct PaletteSimulationResult {
    let type: ColorBlindnessType
    let simulatedColors: [SimulatedColor]
    let confusablePairs: [ConfusablePair]
}

/// Protocol for color blindness simulation
protocol ColorBlindnessServiceProtocol {
    /// Simulate how a single color appears under a given color blindness type
    func simulate(_ color: PaletteColor, type: ColorBlindnessType) -> PaletteColor
    /// Simulate an entire palette and find confusable pairs
    func simulatePalette(_ palette: ColorPalette, type: ColorBlindnessType) -> PaletteSimulationResult
}

