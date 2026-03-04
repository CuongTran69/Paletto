import Foundation

/// Compares palettes using CIE LAB delta E distance
final class PaletteComparisonService: PaletteComparisonServiceProtocol {

    func compare(_ palette1: ColorPalette, with palette2: ColorPalette) -> PaletteComparisonResult {
        let count = min(palette1.colors.count, palette2.colors.count)
        guard count > 0 else {
            return PaletteComparisonResult(pairs: [], averageDeltaE: 0, overallBadge: .identical)
        }

        var pairs: [ColorComparisonResult] = []
        var totalDeltaE: CGFloat = 0

        for i in 0..<count {
            let c1 = palette1.colors[i]
            let c2 = palette2.colors[i]
            let dE = c1.labColor.distance(to: c2.labColor)
            let b = badge(for: dE)
            pairs.append(ColorComparisonResult(color1: c1, color2: c2, deltaE: dE, badge: b))
            totalDeltaE += dE
        }

        // Handle unmatched colors (if palettes have different sizes)
        if palette1.colors.count > count {
            for i in count..<palette1.colors.count {
                let c1 = palette1.colors[i]
                let placeholder = PaletteColor(red: 0.5, green: 0.5, blue: 0.5)
                let dE: CGFloat = 100 // max distance for unmatched
                pairs.append(ColorComparisonResult(color1: c1, color2: placeholder, deltaE: dE, badge: .veryDifferent))
                totalDeltaE += dE
            }
        } else if palette2.colors.count > count {
            for i in count..<palette2.colors.count {
                let c2 = palette2.colors[i]
                let placeholder = PaletteColor(red: 0.5, green: 0.5, blue: 0.5)
                let dE: CGFloat = 100
                pairs.append(ColorComparisonResult(color1: placeholder, color2: c2, deltaE: dE, badge: .veryDifferent))
                totalDeltaE += dE
            }
        }

        let avgDeltaE = totalDeltaE / CGFloat(pairs.count)
        let overallBadge = badge(for: avgDeltaE)

        return PaletteComparisonResult(pairs: pairs, averageDeltaE: avgDeltaE, overallBadge: overallBadge)
    }

    func badge(for deltaE: CGFloat) -> SimilarityBadge {
        switch deltaE {
        case ..<1: return .identical
        case ..<5: return .similar
        case ..<10: return .different
        default: return .veryDifferent
        }
    }
}

