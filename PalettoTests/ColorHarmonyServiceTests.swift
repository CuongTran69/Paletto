import XCTest
@testable import Paletto

final class ColorHarmonyServiceTests: XCTestCase {

    var sut: ColorHarmonyService!

    override func setUp() {
        super.setUp()
        sut = ColorHarmonyService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testComplementaryGeneratesTwoColors180DegreesApart() {
        let source = PaletteColor.fromHSB(hue: 0, saturation: 1.0, brightness: 1.0)
        let colors = sut.generateHarmony(from: source, type: .complementary)

        XCTAssertEqual(colors.count, 2)
        XCTAssertEqual(colors[0].hue, 0, accuracy: 1.0)
        XCTAssertEqual(colors[1].hue, 180, accuracy: 1.0)
    }

    func testTriadicGeneratesThreeColors() {
        let source = PaletteColor.fromHSB(hue: 30, saturation: 0.8, brightness: 0.9)
        let colors = sut.generateHarmony(from: source, type: .triadic)

        XCTAssertEqual(colors.count, 3)
        XCTAssertEqual(colors[0].hue, 30, accuracy: 1.0)
        XCTAssertEqual(colors[1].hue, 150, accuracy: 1.0)
        XCTAssertEqual(colors[2].hue, 270, accuracy: 1.0)
    }

    func testSquareGeneratesFourColors90DegreesApart() {
        let source = PaletteColor.fromHSB(hue: 15, saturation: 0.7, brightness: 0.8)
        let colors = sut.generateHarmony(from: source, type: .square)

        XCTAssertEqual(colors.count, 4)
        XCTAssertEqual(colors[0].hue, 15, accuracy: 1.0)
        XCTAssertEqual(colors[1].hue, 105, accuracy: 1.0)
        XCTAssertEqual(colors[2].hue, 195, accuracy: 1.0)
        XCTAssertEqual(colors[3].hue, 285, accuracy: 1.0)
    }

    func testMonochromaticSharesSameHue() {
        let source = PaletteColor.fromHSB(hue: 210, saturation: 0.8, brightness: 0.7)
        let colors = sut.generateHarmony(from: source, type: .monochromatic)

        XCTAssertEqual(colors.count, 4)
        for color in colors {
            XCTAssertEqual(color.hue, 210, accuracy: 1.5, "All monochromatic colors must share the source hue")
        }
    }
}

