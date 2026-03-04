import Foundation

/// WCAG 2.2 contrast checker and color role assignment service
final class ContrastCheckerService: ContrastCheckerServiceProtocol {

    // MARK: - Contrast Ratio

    func contrastRatio(between color1: PaletteColor, and color2: PaletteColor) -> ContrastResult {
        let ratio = color1.contrastRatio(with: color2)
        return ContrastResult(
            ratio: ratio,
            normalTextLevel: wcagLevel(for: ratio, isLargeText: false),
            largeTextLevel: wcagLevel(for: ratio, isLargeText: true)
        )
    }

    func contrastMatrix(for colors: [PaletteColor]) -> [[ContrastResult]] {
        let count = colors.count
        var matrix = [[ContrastResult]](
            repeating: [ContrastResult](
                repeating: ContrastResult(ratio: 1, normalTextLevel: .fail, largeTextLevel: .fail),
                count: count
            ),
            count: count
        )

        for i in 0..<count {
            for j in 0..<count {
                matrix[i][j] = contrastRatio(between: colors[i], and: colors[j])
            }
        }
        return matrix
    }

    // MARK: - Role Assignment

    func assignRoles(to colors: [PaletteColor]) -> [PaletteColor] {
        guard colors.count >= 2 else { return colors }

        var result = colors
        let sorted = colors.enumerated().sorted { $0.element.relativeLuminance > $1.element.relativeLuminance }

        // Lightest → background
        let bgIndex = sorted.first?.offset ?? 0
        result[bgIndex].role = .background

        // Darkest → text
        let textIndex = sorted.last?.offset ?? (colors.count - 1)
        result[textIndex].role = .text

        // Check contrast between bg and text, auto-fix if needed
        let bgTextContrast = result[bgIndex].contrastRatio(with: result[textIndex])
        if bgTextContrast < Constants.Contrast.aaNormalText {
            if let fixed = adjustForContrast(
                color: result[textIndex],
                against: result[bgIndex],
                targetRatio: Constants.Contrast.aaNormalText,
                darken: true
            ) {
                result[textIndex] = fixed
                result[textIndex].role = .text
            }
        }

        // Most saturated of remaining → accent
        let remaining = result.enumerated().filter { $0.element.role == nil }
        if let accentEntry = remaining.max(by: { $0.element.saturation < $1.element.saturation }) {
            result[accentEntry.offset].role = .accent
        }

        // Assign primary and secondary to remaining
        let stillRemaining = result.enumerated().filter { $0.element.role == nil }
        if let first = stillRemaining.first {
            result[first.offset].role = .primary
        }
        if stillRemaining.count > 1, let second = stillRemaining.dropFirst().first {
            result[second.offset].role = .secondary
        }

        // Any extras without role get secondary
        for i in 0..<result.count where result[i].role == nil {
            result[i].role = .secondary
        }

        return result
    }

    // MARK: - Auto-Fix

    func suggestFix(
        for color: PaletteColor,
        against background: PaletteColor,
        targetLevel: WCAGLevel
    ) -> PaletteColor? {
        let targetRatio: CGFloat
        switch targetLevel {
        case .aa: targetRatio = Constants.Contrast.aaNormalText
        case .aaa: targetRatio = Constants.Contrast.aaaNormalText
        case .fail: return nil
        }

        let shouldDarken = color.relativeLuminance > background.relativeLuminance
        return adjustForContrast(
            color: color,
            against: background,
            targetRatio: targetRatio,
            darken: !shouldDarken
        )
    }

    // MARK: - Private

    private func wcagLevel(for ratio: CGFloat, isLargeText: Bool) -> WCAGLevel {
        if isLargeText {
            if ratio >= Constants.Contrast.aaaLargeText { return .aaa }
            if ratio >= Constants.Contrast.aaLargeText { return .aa }
        } else {
            if ratio >= Constants.Contrast.aaaNormalText { return .aaa }
            if ratio >= Constants.Contrast.aaNormalText { return .aa }
        }
        return .fail
    }

    /// Adjust a color's lightness to meet target contrast ratio
    private func adjustForContrast(
        color: PaletteColor,
        against background: PaletteColor,
        targetRatio: CGFloat,
        darken: Bool
    ) -> PaletteColor? {
        var lab = color.labColor
        let step: CGFloat = darken ? -1.0 : 1.0

        for _ in 0..<100 {
            let candidate = PaletteColor.fromLAB(lab)
            let ratio = candidate.contrastRatio(with: background)
            if ratio >= targetRatio {
                return candidate
            }
            let newL = lab.l + step
            guard newL >= 0, newL <= 100 else { return nil }
            lab = CIELABColor(l: newL, a: lab.a, b: lab.b)
        }
        return nil
    }
}

