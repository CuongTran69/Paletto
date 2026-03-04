import Foundation

/// Color harmony types based on color wheel theory
enum HarmonyType: String, CaseIterable, Identifiable {
    case complementary
    case analogous
    case triadic
    case splitComplementary
    case tetradic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .complementary: return L10n.harmonyComplementary.localized
        case .analogous: return L10n.harmonyAnalogous.localized
        case .triadic: return L10n.harmonyTriadic.localized
        case .splitComplementary: return L10n.harmonySplitComplementary.localized
        case .tetradic: return L10n.harmonyTetradic.localized
        }
    }

    var iconName: String {
        switch self {
        case .complementary: return "arrow.left.and.right"
        case .analogous: return "arrow.right"
        case .triadic: return "triangle"
        case .splitComplementary: return "arrow.triangle.branch"
        case .tetradic: return "square"
        }
    }

    var description: String {
        switch self {
        case .complementary: return L10n.harmonyComplementaryDesc.localized
        case .analogous: return L10n.harmonyAnalogousDesc.localized
        case .triadic: return L10n.harmonyTriadicDesc.localized
        case .splitComplementary: return L10n.harmonySplitComplementaryDesc.localized
        case .tetradic: return L10n.harmonyTetradicDesc.localized
        }
    }

    /// Number of colors generated (including source)
    var colorCount: Int {
        switch self {
        case .complementary: return 2
        case .analogous: return 3
        case .triadic: return 3
        case .splitComplementary: return 3
        case .tetradic: return 4
        }
    }
}

