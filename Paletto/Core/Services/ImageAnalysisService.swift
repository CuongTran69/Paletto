import UIKit

/// Analyzes image pixel data for color statistics
final class ImageAnalysisService: ImageAnalysisServiceProtocol {

    func analyze(image: UIImage) -> ImageAnalysisResult {
        // Downsample for performance
        let targetSize = CGSize(width: Constants.Image.downsampleSize, height: Constants.Image.downsampleSize)
        let resized = image.resized(to: targetSize) ?? image

        guard let pixels = resized.pixelData(), !pixels.isEmpty else {
            return emptyResult()
        }

        // Convert to PaletteColors for HSB access
        let colors = pixels.map { PaletteColor(red: $0.r, green: $0.g, blue: $0.b) }

        let dominant = computeDominantColors(from: colors)
        let (warm, cool) = computeWarmCoolRatio(from: colors)
        let satDist = computeSaturationDistribution(from: colors)
        let briDist = computeBrightnessDistribution(from: colors)
        let mood = determineMood(warm: warm, cool: cool, saturation: satDist, brightness: briDist)

        return ImageAnalysisResult(
            dominantColors: dominant,
            warmPercentage: warm,
            coolPercentage: cool,
            saturationDistribution: satDist,
            brightnessDistribution: briDist,
            mood: mood
        )
    }

    // MARK: - Dominant Colors (simplified k-means on hue buckets)

    private func computeDominantColors(from colors: [PaletteColor]) -> [DominantColor] {
        // Bucket by hue (36 buckets of 10° each)
        var buckets = [[PaletteColor]](repeating: [], count: 36)
        for c in colors {
            let bucket = min(Int(c.hue / 10.0), 35)
            buckets[bucket].append(c)
        }

        // Sort buckets by count, take top 5
        let sorted = buckets.enumerated()
            .filter { !$0.element.isEmpty }
            .sorted { $0.element.count > $1.element.count }
            .prefix(5)

        let total = CGFloat(colors.count)
        return sorted.map { (_, bucket) in
            // Average color in bucket
            let avgR = bucket.map(\.red).reduce(0, +) / CGFloat(bucket.count)
            let avgG = bucket.map(\.green).reduce(0, +) / CGFloat(bucket.count)
            let avgB = bucket.map(\.blue).reduce(0, +) / CGFloat(bucket.count)
            let avgColor = PaletteColor(red: avgR, green: avgG, blue: avgB)
            let pct = CGFloat(bucket.count) / total * 100.0
            return DominantColor(color: avgColor, percentage: pct)
        }
    }

    // MARK: - Warm/Cool Ratio

    private func computeWarmCoolRatio(from colors: [PaletteColor]) -> (warm: CGFloat, cool: CGFloat) {
        var warmCount: CGFloat = 0
        var coolCount: CGFloat = 0
        for c in colors {
            let hue = c.hue // 0-360
            // Warm: 0-60° and 300-360°, Cool: 60-300°
            if hue <= 60 || hue >= 300 {
                warmCount += 1
            } else {
                coolCount += 1
            }
        }
        let total = warmCount + coolCount
        guard total > 0 else { return (50, 50) }
        return (warmCount / total * 100, coolCount / total * 100)
    }

    // MARK: - Saturation Distribution

    private func computeSaturationDistribution(from colors: [PaletteColor]) -> DistributionBreakdown {
        var low: CGFloat = 0, med: CGFloat = 0, high: CGFloat = 0
        for c in colors {
            let s = c.saturation
            if s < 0.33 { low += 1 }
            else if s < 0.66 { med += 1 }
            else { high += 1 }
        }
        let total = CGFloat(colors.count)
        guard total > 0 else { return DistributionBreakdown(low: 33, medium: 34, high: 33) }
        return DistributionBreakdown(
            low: low / total * 100,
            medium: med / total * 100,
            high: high / total * 100
        )
    }

    // MARK: - Brightness Distribution

    private func computeBrightnessDistribution(from colors: [PaletteColor]) -> DistributionBreakdown {
        var low: CGFloat = 0, med: CGFloat = 0, high: CGFloat = 0
        for c in colors {
            let b = c.brightness
            if b < 0.33 { low += 1 }
            else if b < 0.66 { med += 1 }
            else { high += 1 }
        }
        let total = CGFloat(colors.count)
        guard total > 0 else { return DistributionBreakdown(low: 33, medium: 34, high: 33) }
        return DistributionBreakdown(
            low: low / total * 100,
            medium: med / total * 100,
            high: high / total * 100
        )
    }

    // MARK: - Mood Detection

    private func determineMood(
        warm: CGFloat,
        cool: CGFloat,
        saturation: DistributionBreakdown,
        brightness: DistributionBreakdown
    ) -> ColorMood {
        let isWarm = warm > 60
        let isCool = cool > 60
        let isVibrant = saturation.high > 40
        let isMuted = saturation.low > 50
        let isDark = brightness.low > 50
        let isLight = brightness.high > 50
        let isColorful = saturation.high > 30 && saturation.medium > 30

        if isDark && isMuted { return .darkMoody }
        if isLight && isMuted { return .lightAiry }
        if isColorful && !isWarm && !isCool { return .colorful }
        if isWarm && isVibrant { return .warmVibrant }
        if isWarm && isMuted { return .warmMuted }
        if isCool && isVibrant { return .coolVibrant }
        if isCool && isMuted { return .coolMuted }
        return .neutralBalanced
    }

    private func emptyResult() -> ImageAnalysisResult {
        ImageAnalysisResult(
            dominantColors: [],
            warmPercentage: 50,
            coolPercentage: 50,
            saturationDistribution: DistributionBreakdown(low: 33, medium: 34, high: 33),
            brightnessDistribution: DistributionBreakdown(low: 33, medium: 34, high: 33),
            mood: .neutralBalanced
        )
    }
}

