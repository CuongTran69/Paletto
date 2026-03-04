import Foundation

/// Manages user settings via UserDefaults
final class SettingsManager {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Settings

    var defaultColorCount: Int {
        get {
            let value = defaults.integer(forKey: Constants.Storage.settingsDefaultColorCountKey)
            return value > 0 ? value : Constants.Palette.defaultColorCount
        }
        set {
            let clamped = min(max(newValue, Constants.Palette.minColorCount), Constants.Palette.maxColorCount)
            defaults.set(clamped, forKey: Constants.Storage.settingsDefaultColorCountKey)
        }
    }

    var hapticFeedbackEnabled: Bool {
        get {
            if defaults.object(forKey: Constants.Storage.settingsHapticFeedbackKey) == nil {
                return true // Default enabled
            }
            return defaults.bool(forKey: Constants.Storage.settingsHapticFeedbackKey)
        }
        set {
            defaults.set(newValue, forKey: Constants.Storage.settingsHapticFeedbackKey)
        }
    }

    var defaultExportFormat: ExportFormat {
        get {
            let raw = defaults.string(forKey: Constants.Storage.settingsDefaultExportFormat) ?? ""
            return ExportFormat(rawValue: raw) ?? .image
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.Storage.settingsDefaultExportFormat)
        }
    }

    var language: AppLanguage {
        get {
            let raw = defaults.string(forKey: Constants.Storage.settingsLanguageKey) ?? ""
            return AppLanguage(rawValue: raw) ?? .english
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.Storage.settingsLanguageKey)
        }
    }

    var theme: AppTheme {
        get {
            let raw = defaults.string(forKey: Constants.Storage.settingsThemeKey) ?? ""
            return AppTheme(rawValue: raw) ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.Storage.settingsThemeKey)
        }
    }
}

