import SwiftUI

/// Represents a single color in a palette with its metadata
struct PaletteColor: Codable, Identifiable, Equatable {
    let id: UUID
    var hex: String
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    var role: ColorRole?

    init(
        id: UUID = UUID(),
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1.0,
        role: ColorRole? = nil
    ) {
        self.id = id
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.role = role
        self.hex = Self.toHex(red: red, green: green, blue: blue)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// RGB string formatted as "R, G, B" (0-255)
    var rgbString: String {
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        return "\(r), \(g), \(b)"
    }

    /// HSB string formatted as "H°, S%, B%"
    var hsbString: String {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return "\(Int(round(h * 360)))°, \(Int(round(s * 100)))%, \(Int(round(b * 100)))%"
    }

    /// Relative luminance per WCAG 2.2
    var relativeLuminance: CGFloat {
        func linearize(_ value: CGFloat) -> CGFloat {
            value <= 0.04045
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    /// Saturation value (0-1)
    var saturation: CGFloat {
        var s: CGFloat = 0
        uiColor.getHue(nil, saturation: &s, brightness: nil, alpha: nil)
        return s
    }

    /// Hue value (0-360 degrees)
    var hue: CGFloat {
        var h: CGFloat = 0
        uiColor.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        return h * 360
    }

    /// Brightness value (0-1)
    var brightness: CGFloat {
        var b: CGFloat = 0
        uiColor.getHue(nil, saturation: nil, brightness: &b, alpha: nil)
        return b
    }

    /// Create PaletteColor from HSB values
    static func fromHSB(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> PaletteColor {
        let ui = UIColor(hue: hue / 360.0, saturation: saturation, brightness: brightness, alpha: 1.0)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return PaletteColor(red: r, green: g, blue: b)
    }

    private static func toHex(red: CGFloat, green: CGFloat, blue: CGFloat) -> String {
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

