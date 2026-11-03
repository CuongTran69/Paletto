import XCTest
@testable import Paletto

final class ExportServiceTests: XCTestCase {

    var sut: ExportService!

    override func setUp() {
        super.setUp()
        sut = ExportService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testExportSwiftUINoDuplicateIdentifiersWhenRolesMissing() {
        // Given a palette where all colors have role = nil
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0),
            PaletteColor(red: 0, green: 1.0, blue: 0),
            PaletteColor(red: 0, green: 0, blue: 1.0)
        ]
        let palette = ColorPalette(name: "Test Palette", colors: colors)

        // When
        let output = sut.exportAsSwiftUI(palette: palette)

        // Then: identifiers must be unique
        XCTAssertTrue(output.contains("paletteColor1"))
        XCTAssertTrue(output.contains("paletteColor2"))
        XCTAssertTrue(output.contains("paletteColor3"))
    }

    func testExportSwiftUINoDuplicateWhenRolesDuplicate() {
        // Given two colors with the same role .primary
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0, role: .primary),
            PaletteColor(red: 0, green: 1.0, blue: 0, role: .primary)
        ]
        let palette = ColorPalette(name: "Test Palette", colors: colors)

        // When
        let output = sut.exportAsSwiftUI(palette: palette)

        // Then
        XCTAssertTrue(output.contains("palettePrimary"))
        XCTAssertTrue(output.contains("palettePrimary2"))
    }

    func testExportCSSUniqueVariables() {
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0, role: .primary),
            PaletteColor(red: 0, green: 1.0, blue: 0, role: .primary),
            PaletteColor(red: 0, green: 0, blue: 1.0)
        ]
        let palette = ColorPalette(name: "Test Palette", colors: colors)

        let output = sut.exportAsCSS(palette: palette)

        XCTAssertTrue(output.contains("--color-primary:"))
        XCTAssertTrue(output.contains("--color-primary-2:"))
        XCTAssertTrue(output.contains("--color-color3:"))
    }

    func testExportTailwindConfig() {
        let colors = [
            PaletteColor(red: 0.2, green: 0.4, blue: 0.8, role: .primary)
        ]
        let palette = ColorPalette(name: "Tailwind Test", colors: colors)

        let output = sut.exportAsTailwind(palette: palette)

        XCTAssertTrue(output.contains("module.exports"))
        XCTAssertTrue(output.contains("'primary':"))
    }

    func testExportCompose() {
        let colors = [
            PaletteColor(red: 1.0, green: 1.0, blue: 1.0, role: .background)
        ]
        let palette = ColorPalette(name: "Compose Test", colors: colors)

        let output = sut.exportAsCompose(palette: palette)

        XCTAssertTrue(output.contains("package com.paletto.theme"))
        XCTAssertTrue(output.contains("val PaletteBackground = Color(0xFFFFFFFF)"))
    }

    func testExportFlutter() {
        let colors = [
            PaletteColor(red: 0, green: 0, blue: 0, role: .text)
        ]
        let palette = ColorPalette(name: "Flutter Test", colors: colors)

        let output = sut.exportAsFlutter(palette: palette)

        XCTAssertTrue(output.contains("class AppPalette"))
        XCTAssertTrue(output.contains("static const Color text = Color(0xFF000000);"))
    }

    func testExportSVG() {
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0, role: .accent)
        ]
        let palette = ColorPalette(name: "SVG Test", colors: colors)

        let output = sut.exportAsSVG(palette: palette)

        XCTAssertTrue(output.contains("<svg"))
        XCTAssertTrue(output.contains("</svg>"))
        XCTAssertTrue(output.contains(colors[0].hex))
    }

    func testExportJSONTokensNoKeyCollision() {
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0, role: .secondary),
            PaletteColor(red: 0, green: 1.0, blue: 0, role: .secondary)
        ]
        let palette = ColorPalette(name: "JSON Test", colors: colors)

        let output = sut.exportAsJSONTokens(palette: palette)

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let colorsDict = json["colors"] as? [String: Any] else {
            XCTFail("Output is not valid JSON")
            return
        }

        XCTAssertEqual(colorsDict.count, 2, "Both secondary colors should be present without overwriting")
        XCTAssertNotNil(colorsDict["secondary"])
        XCTAssertNotNil(colorsDict["secondary-2"])
    }
}

