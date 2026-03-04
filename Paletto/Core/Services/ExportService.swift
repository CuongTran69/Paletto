import UIKit

/// Generates export content in various formats
final class ExportService {

    // MARK: - Export as Image

    func exportAsImage(palette: ColorPalette) -> UIImage? {
        let width: CGFloat = 600
        let swatchHeight: CGFloat = 80
        let labelHeight: CGFloat = 30
        let padding: CGFloat = 20
        let totalHeight = padding * 3 + swatchHeight + labelHeight + 40

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: totalHeight)
        )

        return renderer.image { context in
            let ctx = context.cgContext

            // Background
            UIColor.systemBackground.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: totalHeight))

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            (palette.name as NSString).draw(
                at: CGPoint(x: padding, y: padding),
                withAttributes: titleAttrs
            )

            // Color swatches
            let swatchWidth = (width - padding * 2 - CGFloat(palette.colors.count - 1) * 4)
                / CGFloat(palette.colors.count)
            let swatchY = padding + 36

            for (i, color) in palette.colors.enumerated() {
                let x = padding + CGFloat(i) * (swatchWidth + 4)

                // Swatch
                let rect = CGRect(x: x, y: swatchY, width: swatchWidth, height: swatchHeight)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                color.uiColor.setFill()
                path.fill()

                // HEX label
                let hexAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let hexSize = (color.hex as NSString).size(withAttributes: hexAttrs)
                let hexX = x + (swatchWidth - hexSize.width) / 2
                (color.hex as NSString).draw(
                    at: CGPoint(x: hexX, y: swatchY + swatchHeight + 6),
                    withAttributes: hexAttrs
                )

                // Role label
                if let role = color.role {
                    let roleAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                        .foregroundColor: UIColor.tertiaryLabel
                    ]
                    let roleSize = (role.displayName as NSString).size(withAttributes: roleAttrs)
                    let roleX = x + (swatchWidth - roleSize.width) / 2
                    (role.displayName as NSString).draw(
                        at: CGPoint(x: roleX, y: swatchY + swatchHeight + 20),
                        withAttributes: roleAttrs
                    )
                }
            }
        }
    }

    // MARK: - Export as SwiftUI Code

    func exportAsSwiftUI(palette: ColorPalette) -> String {
        var lines = ["import SwiftUI", "", "extension Color {"]
        for color in palette.colors {
            let name = roleName(color.role)
            lines.append("    static let palette\(name) = Color(red: \(f(color.red)), green: \(f(color.green)), blue: \(f(color.blue)))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as CSS

    func exportAsCSS(palette: ColorPalette) -> String {
        var lines = [":root {"]
        for color in palette.colors {
            let name = cssName(color.role)
            lines.append("    --color-\(name): \(color.hex);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as HEX List

    func exportAsHexList(palette: ColorPalette) -> String {
        palette.colors.map { color in
            if let role = color.role {
                return "\(color.hex) // \(role.displayName)"
            }
            return color.hex
        }.joined(separator: "\n")
    }

    // MARK: - Export as JSON Tokens

    func exportAsJSONTokens(palette: ColorPalette) -> String {
        var tokens: [String: Any] = [:]
        for color in palette.colors {
            let name = cssName(color.role)
            tokens[name] = [
                "value": color.hex,
                "type": "color",
                "description": color.role?.displayName ?? "Color"
            ]
        }
        let wrapper: [String: Any] = [
            "palette": palette.name,
            "colors": tokens
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: wrapper,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Helpers

    private func roleName(_ role: ColorRole?) -> String {
        (role?.displayName ?? "Color").replacingOccurrences(of: " ", with: "")
    }

    private func cssName(_ role: ColorRole?) -> String {
        role?.rawValue ?? "color"
    }

    private func f(_ value: CGFloat) -> String {
        String(format: "%.3f", value)
    }
}

