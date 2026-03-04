import Foundation

extension String {
    /// Convenience: look up this string as a localization key
    var localized: String {
        LocalizationManager.shared.localized(self)
    }

    /// Convenience: look up with interpolation args
    func localized(args: [String: String]) -> String {
        LocalizationManager.shared.localized(self, args: args)
    }
}

