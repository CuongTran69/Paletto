import SwiftUI

/// Singleton managing app theme — controls light/dark/system mode
final class ThemeManager: ThemeManagerProtocol {

    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            guard oldValue != currentTheme else { return }
            SettingsManager.shared.theme = currentTheme
        }
    }

    /// Returns nil for .system (follow OS), or explicit scheme for light/dark
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    private init() {
        self.currentTheme = SettingsManager.shared.theme
    }
}

