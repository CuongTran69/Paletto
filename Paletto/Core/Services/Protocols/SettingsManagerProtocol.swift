import Foundation

/// Protocol for accessing user settings
protocol SettingsManagerProtocol {
    var defaultColorCount: Int { get set }
    var hapticFeedbackEnabled: Bool { get set }
    var defaultExportFormat: ExportFormat { get set }
    var language: AppLanguage { get set }
    var theme: AppTheme { get set }
}

