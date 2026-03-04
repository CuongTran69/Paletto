import Foundation

/// Similarity badge based on delta E distance
enum SimilarityBadge: String {
    case identical   // ΔE < 1
    case similar     // ΔE < 5
    case different   // ΔE < 10
    case veryDifferent // ΔE >= 10

    var displayName: String {
        switch self {
        case .identical: return L10n.comparisonBadgeIdentical.localized
        case .similar: return L10n.comparisonBadgeSimilar.localized
        case .different: return L10n.comparisonBadgeDifferent.localized
        case .veryDifferent: return L10n.comparisonBadgeVeryDifferent.localized
        }
    }

    var iconName: String {
        switch self {
        case .identical: return "equal.circle.fill"
        case .similar: return "checkmark.circle.fill"
        case .different: return "arrow.left.arrow.right.circle.fill"
        case .veryDifferent: return "xmark.circle.fill"
        }
    }
}

/// Result of comparing two colors
struct ColorComparisonResult: Identifiable {
    let id = UUID()
    let color1: PaletteColor
    let color2: PaletteColor
    let deltaE: CGFloat
    let badge: SimilarityBadge
}

/// Result of comparing two palettes
struct PaletteComparisonResult {
    let pairs: [ColorComparisonResult]
    let averageDeltaE: CGFloat
    let overallBadge: SimilarityBadge
}

/// Protocol for comparing palettes
protocol PaletteComparisonServiceProtocol {
    /// Compare two palettes color-by-color (matched by index)
    func compare(_ palette1: ColorPalette, with palette2: ColorPalette) -> PaletteComparisonResult
    /// Get similarity badge for a delta E value
    func badge(for deltaE: CGFloat) -> SimilarityBadge
}

