import Foundation

/// Defines the semantic role of a color in a palette/color system
enum ColorRole: String, Codable, CaseIterable, Identifiable {
    case background
    case primary
    case secondary
    case accent
    case text

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .background: return "role.background".localized
        case .primary: return "role.primary".localized
        case .secondary: return "role.secondary".localized
        case .accent: return "role.accent".localized
        case .text: return "role.text".localized
        }
    }

    var shortName: String {
        switch self {
        case .background: return "role.background.short".localized
        case .primary: return "role.primary.short".localized
        case .secondary: return "role.secondary.short".localized
        case .accent: return "role.accent.short".localized
        case .text: return "role.text.short".localized
        }
    }

    var iconName: String {
        switch self {
        case .background: return "rectangle.fill"
        case .primary: return "star.fill"
        case .secondary: return "circle.fill"
        case .accent: return "bolt.fill"
        case .text: return "textformat"
        }
    }
}

