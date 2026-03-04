import Foundation

/// Encodes/decodes palettes as shareable URLs
/// Format: paletto://palette?n=NAME&c=HEX1,HEX2,...
final class PaletteSharingService {

    static let scheme = "paletto"
    static let host = "palette"

    // MARK: - Encode

    /// Encode a palette into a shareable URL
    func encode(palette: ColorPalette) -> URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host

        let hexColors = palette.colors.map { $0.hex.replacingOccurrences(of: "#", with: "") }
        let colorString = hexColors.joined(separator: ",")

        components.queryItems = [
            URLQueryItem(name: "n", value: palette.name),
            URLQueryItem(name: "c", value: colorString)
        ]

        return components.url
    }

    // MARK: - Decode

    /// Decode a URL into a ColorPalette (returns nil if invalid)
    func decode(url: URL) -> ColorPalette? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == Self.scheme,
              components.host == Self.host else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let name = queryItems.first(where: { $0.name == "n" })?.value ?? "Shared Palette"
        guard let colorString = queryItems.first(where: { $0.name == "c" })?.value,
              !colorString.isEmpty else {
            return nil
        }

        let hexValues = colorString.split(separator: ",").map(String.init)
        guard !hexValues.isEmpty else { return nil }

        let colors = hexValues.compactMap { hex -> PaletteColor? in
            parseHex(hex)
        }

        guard !colors.isEmpty else { return nil }

        return ColorPalette(name: name, colors: colors)
    }

    // MARK: - Private

    private func parseHex(_ hex: String) -> PaletteColor? {
        let clean = hex.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")

        guard clean.count == 6 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        return PaletteColor(red: r, green: g, blue: b)
    }
}

