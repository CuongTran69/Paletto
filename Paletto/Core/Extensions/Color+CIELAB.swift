import UIKit

/// CIE LAB color representation for perceptually uniform color distance
struct CIELABColor {
    let l: CGFloat // Lightness (0-100)
    let a: CGFloat // Green-Red (-128 to 127)
    let b: CGFloat // Blue-Yellow (-128 to 127)

    /// Euclidean distance in LAB space (perceptually uniform)
    func distance(to other: CIELABColor) -> CGFloat {
        let dl = l - other.l
        let da = a - other.a
        let db = b - other.b
        return sqrt(dl * dl + da * da + db * db)
    }
}

extension PaletteColor {
    /// Convert to CIE LAB color space via XYZ
    var labColor: CIELABColor {
        // Step 1: sRGB → Linear RGB
        func linearize(_ v: CGFloat) -> CGFloat {
            v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let lr = linearize(red)
        let lg = linearize(green)
        let lb = linearize(blue)

        // Step 2: Linear RGB → XYZ (D65 illuminant)
        let x = (0.4124564 * lr + 0.3575761 * lg + 0.1804375 * lb) / 0.95047
        let y = (0.2126729 * lr + 0.7151522 * lg + 0.0721750 * lb) / 1.00000
        let z = (0.0193339 * lr + 0.0961168 * lg + 0.8504880 * lb) / 1.08883

        // Step 3: XYZ → LAB
        func f(_ t: CGFloat) -> CGFloat {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : (903.3 * t + 16.0) / 116.0
        }
        let fx = f(x)
        let fy = f(y)
        let fz = f(z)

        let l = 116.0 * fy - 16.0
        let a = 500.0 * (fx - fy)
        let b = 200.0 * (fy - fz)

        return CIELABColor(l: l, a: a, b: b)
    }

    /// Create PaletteColor from CIE LAB values
    static func fromLAB(_ lab: CIELABColor) -> PaletteColor {
        // Step 1: LAB → XYZ
        let fy = (lab.l + 16.0) / 116.0
        let fx = lab.a / 500.0 + fy
        let fz = fy - lab.b / 200.0

        func fInverse(_ t: CGFloat) -> CGFloat {
            let t3 = t * t * t
            return t3 > 0.008856 ? t3 : (116.0 * t - 16.0) / 903.3
        }

        let x = 0.95047 * fInverse(fx)
        let y = 1.00000 * fInverse(fy)
        let z = 1.08883 * fInverse(fz)

        // Step 2: XYZ → Linear RGB
        let lr =  3.2404542 * x - 1.5371385 * y - 0.4985314 * z
        let lg = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
        let lb =  0.0556434 * x - 0.2040259 * y + 1.0572252 * z

        // Step 3: Linear RGB → sRGB
        func gammaCompress(_ v: CGFloat) -> CGFloat {
            let clamped = max(0, min(1, v))
            return clamped <= 0.0031308
                ? 12.92 * clamped
                : 1.055 * pow(clamped, 1.0 / 2.4) - 0.055
        }

        return PaletteColor(
            red: gammaCompress(lr),
            green: gammaCompress(lg),
            blue: gammaCompress(lb)
        )
    }
}

