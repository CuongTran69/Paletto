import UIKit

/// Generates export content in various formats
final class ExportService: ExportServiceProtocol {

    // MARK: - Export as Image

    func exportAsImage(palette: ColorPalette) -> UIImage? {
        guard !palette.colors.isEmpty else { return nil }

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
        var usedCounts: [String: Int] = [:]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            let identifier = "palette\(names.pascalCase)"
            lines.append("    static let \(identifier) = Color(red: \(f(color.red)), green: \(f(color.green)), blue: \(f(color.blue)))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as CSS

    func exportAsCSS(palette: ColorPalette) -> String {
        var lines = [":root {"]
        var usedCounts: [String: Int] = [:]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            lines.append("    --color-\(names.kebabCase): \(color.hex);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as Tailwind CSS

    func exportAsTailwind(palette: ColorPalette) -> String {
        var usedCounts: [String: Int] = [:]
        var lines = [
            "/** @type {import('tailwindcss').Config} */",
            "module.exports = {",
            "  theme: {",
            "    extend: {",
            "      colors: {"
        ]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            lines.append("        '\(names.kebabCase)': '\(color.hex)',")
        }

        lines.append("      }")
        lines.append("    }")
        lines.append("  }")
        lines.append("};")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as Android Compose

    func exportAsCompose(palette: ColorPalette) -> String {
        var usedCounts: [String: Int] = [:]
        var lines = [
            "package com.paletto.theme",
            "",
            "import androidx.compose.ui.graphics.Color",
            ""
        ]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            let hex = color.hex.replacingOccurrences(of: "#", with: "").uppercased()
            lines.append("val Palette\(names.pascalCase) = Color(0xFF\(hex))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as Flutter

    func exportAsFlutter(palette: ColorPalette) -> String {
        var usedCounts: [String: Int] = [:]
        var lines = [
            "import 'package:flutter/material.dart';",
            "",
            "class AppPalette {"
        ]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            let hex = color.hex.replacingOccurrences(of: "#", with: "").uppercased()
            lines.append("  static const Color \(names.camelCase) = Color(0xFF\(hex));")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Export as SVG

    func exportAsSVG(palette: ColorPalette) -> String {
        guard !palette.colors.isEmpty else { return "<svg></svg>" }

        let swatchWidth = 100
        let swatchHeight = 100
        let textHeight = 40
        let padding = 16
        let totalWidth = padding * 2 + palette.colors.count * swatchWidth
        let totalHeight = padding * 2 + swatchHeight + textHeight

        var lines = [
            "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(totalWidth) \(totalHeight)\" width=\"\(totalWidth)\" height=\"\(totalHeight)\">",
            "  <rect width=\"100%\" height=\"100%\" fill=\"#FFFFFF\" rx=\"16\" />"
        ]

        var usedCounts: [String: Int] = [:]
        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            let x = padding + index * swatchWidth
            let y = padding

            // Swatch rect
            lines.append("  <rect x=\"\(x)\" y=\"\(y)\" width=\"\(swatchWidth)\" height=\"\(swatchHeight)\" fill=\"\(color.hex)\" />")
            // Hex text
            lines.append("  <text x=\"\(x + swatchWidth / 2)\" y=\"\(y + swatchHeight + 18)\" font-family=\"monospace\" font-size=\"12\" font-weight=\"bold\" fill=\"#1F2937\" text-anchor=\"middle\">\(color.hex)</text>")
            // Role / name text
            lines.append("  <text x=\"\(x + swatchWidth / 2)\" y=\"\(y + swatchHeight + 32)\" font-family=\"sans-serif\" font-size=\"10\" fill=\"#6B7280\" text-anchor=\"middle\">\(names.kebabCase)</text>")
        }

        lines.append("</svg>")
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
        var usedCounts: [String: Int] = [:]

        for (index, color) in palette.colors.enumerated() {
            let names = uniqueNames(role: color.role, index: index, usedCounts: &usedCounts)
            tokens[names.kebabCase] = [
                "value": color.hex,
                "type": "color",
                "description": color.role?.displayName ?? "Color \(index + 1)"
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

    private struct NameVariations {
        let pascalCase: String
        let camelCase: String
        let kebabCase: String
    }

    private func uniqueNames(
        role: ColorRole?,
        index: Int,
        usedCounts: inout [String: Int]
    ) -> NameVariations {
        let base: String
        if let role = role {
            base = role.rawValue.lowercased()
        } else {
            base = "color\(index + 1)"
        }

        let count = usedCounts[base, default: 0] + 1
        usedCounts[base] = count

        let suffix = count > 1 ? "\(count)" : ""
        let kebabSuffix = count > 1 ? "-\(count)" : ""

        let capitalizedBase = base.prefix(1).uppercased() + base.dropFirst()
        let pascal = "\(capitalizedBase)\(suffix)"
        let camel = "\(base)\(suffix)"
        let kebab = "\(base)\(kebabSuffix)"

        return NameVariations(pascalCase: pascal, camelCase: camel, kebabCase: kebab)
    }

    private func f(_ value: CGFloat) -> String {
        String(format: "%.3f", value)
    }
}
