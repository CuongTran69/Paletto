import SwiftUI

/// Semantic color tokens — uses system colors that auto-adapt to light/dark mode.
/// Custom tokens only for cases where system colors don't cover the need.
enum SemanticColors {
    // MARK: - Backgrounds
    static let appBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let cardBackground = Color(.systemBackground)

    // MARK: - Text
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)

    // MARK: - Semantic
    static let accent = Color.accentColor
    static let destructive = Color.red
    static let success = Color.green
    static let warning = Color.yellow

    // MARK: - Custom (opacity-based, adapt via system)
    static let border = Color(.label).opacity(0.1)
    static let shadow = Color.black.opacity(0.05)
    static let shadowDark = Color.black.opacity(0.2)
    static let overlay = Color.black.opacity(0.7)

    // MARK: - Grouped backgrounds
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)

    // MARK: - Brand Gradient
    static let gradientStart = Color(red: 13/255, green: 148/255, blue: 136/255)   // #0D9488 teal-600
    static let gradientEnd = Color(red: 20/255, green: 184/255, blue: 166/255)     // #14B8A6 teal-500

    /// Primary brand gradient (teal)
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Glass
    static let glassBorder = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.08)
}

