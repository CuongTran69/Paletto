import SwiftUI

/// App-wide constants
enum Constants {
    enum Palette {
        static let defaultColorCount = 5
        static let minColorCount = 3
        static let maxColorCount = 8
    }

    enum Image {
        /// Downsample size for k-means clustering (width & height)
        static let downsampleSize: CGFloat = 100
        /// Maximum iterations for k-means
        static let kMeansMaxIterations = 20
        /// Number of k-means runs to pick best result
        static let kMeansRuns = 3
    }

    enum Magnifier {
        static let size: CGFloat = 80
        static let zoomScale: CGFloat = 2.0
        static let borderWidth: CGFloat = 3
    }

    enum Contrast {
        /// WCAG AA minimum ratio for normal text
        static let aaNormalText: CGFloat = 4.5
        /// WCAG AA minimum ratio for large text
        static let aaLargeText: CGFloat = 3.0
        /// WCAG AAA minimum ratio for normal text
        static let aaaNormalText: CGFloat = 7.0
        /// WCAG AAA minimum ratio for large text
        static let aaaLargeText: CGFloat = 4.5
    }

    enum Storage {
        static let palettesDirectoryName = "Palettes"
        static let settingsDefaultExportFormat = "image"
        static let settingsHapticFeedbackKey = "hapticFeedbackEnabled"
        static let settingsDefaultColorCountKey = "defaultColorCount"
        static let settingsLanguageKey = "appLanguage"
        static let settingsThemeKey = "appTheme"
    }

    enum UI {
        // Corner radii
        static let cornerRadius: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXL: CGFloat = 20
        static let smallCornerRadius: CGFloat = 8

        // Spacing
        static let paddingXL: CGFloat = 24
        static let paddingLarge: CGFloat = 20
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let tinyPadding: CGFloat = 4

        // Swatch sizes
        static let colorSwatchSize: CGFloat = 44
        static let largeColorSwatchSize: CGFloat = 60
        static let swatchSizeMedium: CGFloat = 36

        // Shadows
        static let shadowRadiusSmall: CGFloat = 2
        static let shadowRadiusMedium: CGFloat = 6
        static let shadowRadiusLarge: CGFloat = 12

        // Animation
        static let animationDuration: Double = 0.3
        static let springResponse: Double = 0.35
        static let springDamping: Double = 0.7
    }
}

