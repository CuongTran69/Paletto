import Foundation

/// Supported app themes
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return L10n.settingsThemeLight.localized
        case .dark: return L10n.settingsThemeDark.localized
        case .system: return L10n.settingsThemeSystem.localized
        }
    }
}

