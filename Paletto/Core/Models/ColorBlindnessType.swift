import Foundation

/// Types of color vision deficiency
enum ColorBlindnessType: String, CaseIterable, Identifiable {
    case normal
    case protanopia      // Red-blind
    case deuteranopia    // Green-blind
    case tritanopia      // Blue-blind

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return L10n.blindnessNormal.localized
        case .protanopia: return L10n.blindnessProtanopia.localized
        case .deuteranopia: return L10n.blindnessDeuteranopia.localized
        case .tritanopia: return L10n.blindnessTritanopia.localized
        }
    }

    var shortDescription: String {
        switch self {
        case .normal: return L10n.blindnessNormalDesc.localized
        case .protanopia: return L10n.blindnessProtanopiaDesc.localized
        case .deuteranopia: return L10n.blindnessDeuteranopiaDesc.localized
        case .tritanopia: return L10n.blindnessTritanopiaDesc.localized
        }
    }

    var iconName: String {
        switch self {
        case .normal: return "eye.fill"
        case .protanopia: return "eye.trianglebadge.exclamationmark"
        case .deuteranopia: return "eye.trianglebadge.exclamationmark"
        case .tritanopia: return "eye.trianglebadge.exclamationmark"
        }
    }
}

