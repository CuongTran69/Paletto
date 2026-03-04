import Foundation

/// Protocol for generating color harmonies
protocol ColorHarmonyServiceProtocol {
    /// Generate harmony colors for a source color
    func generateHarmony(from source: PaletteColor, type: HarmonyType) -> [PaletteColor]
}

