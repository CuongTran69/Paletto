import Foundation

/// Encodes/decodes palettes as shareable URLs
/// Format: paletto://palette?n=NAME&c=HEX1,HEX2,...&r=ROLE1,ROLE2,...&t=TAG1,TAG2,...
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

        var items = [
            URLQueryItem(name: "n", value: palette.name),
            URLQueryItem(name: "c", value: colorString)
        ]

        // Encode roles if any color has a role
        let hasAnyRole = palette.colors.contains { $0.role != nil }
        if hasAnyRole {
            let roleStrings = palette.colors.map { $0.role?.rawValue ?? "" }
            items.append(URLQueryItem(name: "r", value: roleStrings.joined(separator: ",")))
        }

        // Encode tags if present
        if !palette.tags.isEmpty {
            items.append(URLQueryItem(name: "t", value: palette.tags.joined(separator: ",")))
        }

        components.queryItems = items
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

        // Optional roles
        let roleStrings = queryItems.first(where: { $0.name == "r" })?.value?
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)

        // Optional tags
        let tags: [String]
        if let tagString = queryItems.first(where: { $0.name == "t" })?.value, !tagString.isEmpty {
            tags = tagString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        } else {
            tags = []
        }

        var colors: [PaletteColor] = []
        for (index, hex) in hexValues.enumerated() {
            guard var color = parseHex(hex) else { continue }
            if let roleStrings = roleStrings, roleStrings.indices.contains(index) {
                let roleRaw = roleStrings[index]
                if !roleRaw.isEmpty, let role = ColorRole(rawValue: roleRaw) {
                    color.role = role
                }
            }
            colors.append(color)
        }

        guard !colors.isEmpty else { return nil }

        return ColorPalette(name: name, colors: colors, tags: tags)
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
