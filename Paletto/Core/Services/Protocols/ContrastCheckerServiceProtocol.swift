import Foundation

/// WCAG compliance level
enum WCAGLevel: String {
    case aa = "AA"
    case aaa = "AAA"
    case fail = "Fail"
}

/// Result of a contrast check between two colors
struct ContrastResult: Equatable {
    let ratio: CGFloat
    let normalTextLevel: WCAGLevel
    let largeTextLevel: WCAGLevel

    var passesAA: Bool { normalTextLevel == .aa || normalTextLevel == .aaa }
    var passesAAA: Bool { normalTextLevel == .aaa }
    var passesAALargeText: Bool { largeTextLevel != .fail }

    var formattedRatio: String {
        String(format: "%.2f:1", ratio)
    }
}

/// Protocol for checking color contrast and assigning roles
protocol ContrastCheckerServiceProtocol {
    /// Calculate contrast ratio between two colors
    func contrastRatio(between color1: PaletteColor, and color2: PaletteColor) -> ContrastResult

    /// Generate a full contrast matrix for all color pairs
    func contrastMatrix(for colors: [PaletteColor]) -> [[ContrastResult]]

    /// Auto-assign roles to colors based on luminance and saturation
    func assignRoles(to colors: [PaletteColor]) -> [PaletteColor]

    /// Suggest an adjusted color that passes the target contrast level
    func suggestFix(
        for color: PaletteColor,
        against background: PaletteColor,
        targetLevel: WCAGLevel
    ) -> PaletteColor?

    /// Update contrast matrix for a single changed color (O(n) instead of O(n²))
    func updateContrastMatrix(_ matrix: [[ContrastResult]], forColorAt index: Int, in colors: [PaletteColor]) -> [[ContrastResult]]
}

