import XCTest
@testable import Paletto

final class PaletteSharingServiceTests: XCTestCase {

    var sut: PaletteSharingService!

    override func setUp() {
        super.setUp()
        sut = PaletteSharingService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testEncodeAndDecodePreservesColorsRolesAndTags() {
        let colors = [
            PaletteColor(red: 1.0, green: 0, blue: 0, role: .primary),
            PaletteColor(red: 0, green: 1.0, blue: 0, role: .background)
        ]
        let palette = ColorPalette(name: "Brand Palette", colors: colors, tags: ["ui", "brand"])

        // When
        guard let url = sut.encode(palette: palette) else {
            XCTFail("Failed to encode palette")
            return
        }

        // Then URL contains roles and tags
        XCTAssertTrue(url.absoluteString.contains("r="))
        XCTAssertTrue(url.absoluteString.contains("t="))

        // When decode
        guard let decoded = sut.decode(url: url) else {
            XCTFail("Failed to decode palette")
            return
        }

        XCTAssertEqual(decoded.name, "Brand Palette")
        XCTAssertEqual(decoded.colors.count, 2)
        XCTAssertEqual(decoded.colors[0].role, .primary)
        XCTAssertEqual(decoded.colors[1].role, .background)
        XCTAssertEqual(decoded.tags, ["ui", "brand"])
    }

    func testDecodeLegacyURLWithoutRolesOrTags() {
        // Legacy URL format without &r= or &t=
        let url = URL(string: "paletto://palette?n=Legacy&c=FF0000,00FF00")!

        guard let decoded = sut.decode(url: url) else {
            XCTFail("Failed to decode legacy URL")
            return
        }

        XCTAssertEqual(decoded.name, "Legacy")
        XCTAssertEqual(decoded.colors.count, 2)
        XCTAssertNil(decoded.colors[0].role)
        XCTAssertNil(decoded.colors[1].role)
        XCTAssertEqual(decoded.tags, [])
    }

    func testDecodeInvalidSchemeReturnsNil() {
        let url = URL(string: "https://palette?n=Test&c=FF0000")!
        XCTAssertNil(sut.decode(url: url))
    }
}

