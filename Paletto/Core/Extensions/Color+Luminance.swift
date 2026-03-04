import SwiftUI

extension PaletteColor {
    /// Calculate WCAG 2.2 contrast ratio between this color and another
    func contrastRatio(with other: PaletteColor) -> CGFloat {
        let l1 = max(relativeLuminance, other.relativeLuminance)
        let l2 = min(relativeLuminance, other.relativeLuminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }
}

