import Foundation

/// Generates color harmonies based on HSB color wheel theory
final class ColorHarmonyService: ColorHarmonyServiceProtocol {

    func generateHarmony(from source: PaletteColor, type: HarmonyType) -> [PaletteColor] {
        let hue = source.hue
        let sat = source.saturation
        let bri = source.brightness

        switch type {
        case .complementary:
            return [0, 180].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .analogous:
            return [-30, 0, 30].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .triadic:
            return [0, 120, 240].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .splitComplementary:
            return [0, 150, 210].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .tetradic:
            // Rectangular harmony (e.g. 0, 60, 180, 240)
            return [0, 60, 180, 240].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .square:
            // 4 points evenly spaced at 90 degrees
            return [0, 90, 180, 270].map { offset in
                PaletteColor.fromHSB(hue: normalizeHue(hue + CGFloat(offset)), saturation: sat, brightness: bri)
            }
        case .monochromatic:
            // Same hue, varying saturation and brightness for a cohesive scale
            let variations: [(s: CGFloat, b: CGFloat)] = [
                (s: max(0.08, sat * 0.35), b: min(0.98, max(0.7, bri * 1.25))), // Light tint
                (s: max(0.15, sat * 0.70), b: min(0.95, max(0.5, bri * 1.10))), // Soft tint
                (s: sat, b: bri),                                              // Source base
                (s: min(1.0, max(0.4, sat * 1.15)), b: max(0.18, bri * 0.55)) // Deep shade
            ]
            return variations.map { v in
                PaletteColor.fromHSB(hue: hue, saturation: v.s, brightness: v.b)
            }
        }
    }

    /// Normalize hue to 0-360 range
    private func normalizeHue(_ hue: CGFloat) -> CGFloat {
        var h = hue.truncatingRemainder(dividingBy: 360)
        if h < 0 { h += 360 }
        return h
    }
}
