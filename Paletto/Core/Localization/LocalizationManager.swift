import Foundation
import SwiftUI

/// Singleton managing app localization — loads JSON translation files, supports interpolation
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            guard oldValue != currentLanguage else { return }
            SettingsManager.shared.language = currentLanguage
            loadTranslations()
        }
    }

    private var translations: [String: String] = [:]
    private var fallbackTranslations: [String: String] = [:]

    private init() {
        let saved = SettingsManager.shared.language
        self.currentLanguage = saved
        loadFallback()
        loadTranslations()
    }

    // MARK: - Public

    /// Get localized string for key
    func localized(_ key: String) -> String {
        translations[key] ?? fallbackTranslations[key] ?? key
    }

    /// Get localized string with interpolation: "{count} colors" + ["count": "5"] → "5 colors"
    func localized(_ key: String, args: [String: String]) -> String {
        var result = localized(key)
        for (placeholder, value) in args {
            result = result.replacingOccurrences(of: "{\(placeholder)}", with: value)
        }
        return result
    }

    // MARK: - Private

    private func loadFallback() {
        fallbackTranslations = loadJSON(for: .english)
    }

    private func loadTranslations() {
        translations = loadJSON(for: currentLanguage)
    }

    private func loadJSON(for language: AppLanguage) -> [String: String] {
        guard let url = Bundle.main.url(
            forResource: language.jsonFileName,
            withExtension: "json"
        ) else { return [:] }

        do {
            let data = try Data(contentsOf: url)
            // Flatten nested JSON: {"screen": {"key": "value"}} → {"screen.key": "value"}
            if let nested = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return flatten(nested)
            }
        } catch {
            print("LocalizationManager: Failed to load \(language.rawValue).json — \(error)")
        }
        return [:]
    }

    /// Flatten nested dictionary into dot-separated keys
    private func flatten(_ dict: [String: Any], prefix: String = "") -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let nested = value as? [String: Any] {
                result.merge(flatten(nested, prefix: fullKey)) { _, new in new }
            } else if let str = value as? String {
                result[fullKey] = str
            }
        }
        return result
    }
}

