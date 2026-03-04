import Foundation

/// Generates color harmonies based on HSB color wheel theory
final class ColorHarmonyService: ColorHarmonyServiceProtocol {

    func generateHarmony(from source: PaletteColor, type: HarmonyType) -> [PaletteColor] {
        let hue = source.hue
        let sat = source.saturation
        let bri = source.brightness

        let offsets: [CGFloat]
        switch type {
        case .complementary:
            offsets = [0, 180]
        case .analogous:
            offsets = [-30, 0, 30]
        case .triadic:
            offsets = [0, 120, 240]
        case .splitComplementary:
            offsets = [0, 150, 210]
        case .tetradic:
            offsets = [0, 90, 180, 270]
        }

        return offsets.map { offset in
            let newHue = normalizeHue(hue + offset)
            return PaletteColor.fromHSB(hue: newHue, saturation: sat, brightness: bri)
        }
    }

    /// Normalize hue to 0-360 range
    private func normalizeHue(_ hue: CGFloat) -> CGFloat {
        var h = hue.truncatingRemainder(dividingBy: 360)
        if h < 0 { h += 360 }
        return h
    }
}

