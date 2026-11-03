import XCTest
@testable import Paletto

final class ColorBlindnessServiceTests: XCTestCase {

    var sut: ColorBlindnessService!

    override func setUp() {
        super.setUp()
        sut = ColorBlindnessService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAchromatopsiaConvertsToGrayscale() {
        // Red color
        let red = PaletteColor(red: 1.0, green: 0, blue: 0)
        let simulated = sut.simulate(red, type: .achromatopsia)

        // For grayscale, R ≈ G ≈ B
        XCTAssertEqual(simulated.red, simulated.green, accuracy: 0.05)
        XCTAssertEqual(simulated.green, simulated.blue, accuracy: 0.05)
    }

    func testNormalVisionDoesNotAlterColor() {
        let color = PaletteColor(red: 0.3, green: 0.6, blue: 0.9)
        let simulated = sut.simulate(color, type: .normal)

        XCTAssertEqual(simulated.red, color.red, accuracy: 0.001)
        XCTAssertEqual(simulated.green, color.green, accuracy: 0.001)
        XCTAssertEqual(simulated.blue, color.blue, accuracy: 0.001)
    }

    func testSimulatePaletteDetectsConfusableColors() {
        // Red and green can be confusable under deuteranopia
        let red = PaletteColor(red: 0.8, green: 0.1, blue: 0.1)
        let brownGreen = PaletteColor(red: 0.5, green: 0.45, blue: 0.1)
        let palette = ColorPalette(name: "Test", colors: [red, brownGreen])

        let result = sut.simulatePalette(palette, type: .deuteranopia)
        XCTAssertEqual(result.simulatedColors.count, 2)
    }
}

