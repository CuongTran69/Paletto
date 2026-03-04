import UIKit

/// A single dominant color with its coverage percentage
struct DominantColor: Identifiable {
    let id = UUID()
    let color: PaletteColor
    let percentage: CGFloat
}

/// Distribution breakdown (e.g., saturation or brightness)
struct DistributionBreakdown {
    let low: CGFloat    // 0-1 percentage
    let medium: CGFloat
    let high: CGFloat
}

/// Color mood label
enum ColorMood: String {
    case warmVibrant = "warm_vibrant"
    case warmMuted = "warm_muted"
    case coolVibrant = "cool_vibrant"
    case coolMuted = "cool_muted"
    case neutralBalanced = "neutral_balanced"
    case darkMoody = "dark_moody"
    case lightAiry = "light_airy"
    case colorful = "colorful"

    var localizationKey: String {
        "analysis.mood.\(rawValue)"
    }
}

/// Complete image analysis result
struct ImageAnalysisResult {
    let dominantColors: [DominantColor]
    let warmPercentage: CGFloat
    let coolPercentage: CGFloat
    let saturationDistribution: DistributionBreakdown
    let brightnessDistribution: DistributionBreakdown
    let mood: ColorMood
}

/// Protocol for image color analysis
protocol ImageAnalysisServiceProtocol {
    /// Analyze an image and return detailed color statistics
    func analyze(image: UIImage) -> ImageAnalysisResult
}

