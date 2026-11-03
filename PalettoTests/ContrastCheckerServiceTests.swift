import XCTest
@testable import Paletto

final class ContrastCheckerServiceTests: XCTestCase {

    var sut: ContrastCheckerService!

    override func setUp() {
        super.setUp()
        sut = ContrastCheckerService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testContrastRatioBlackAndWhiteIs21() {
        let white = PaletteColor(red: 1.0, green: 1.0, blue: 1.0)
        let black = PaletteColor(red: 0, green: 0, blue: 0)

        let result = sut.contrastRatio(between: white, and: black)

        XCTAssertEqual(result.ratio, 21.0, accuracy: 0.1)
        XCTAssertEqual(result.normalTextLevel, .aaa)
        XCTAssertEqual(result.largeTextLevel, .aaa)
    }

    func testContrastRatioSameColorIs1() {
        let color = PaletteColor(red: 0.5, green: 0.5, blue: 0.5)
        let result = sut.contrastRatio(between: color, and: color)

        XCTAssertEqual(result.ratio, 1.0, accuracy: 0.01)
        XCTAssertEqual(result.normalTextLevel, .fail)
    }

    func testSuggestFixImprovesContrastRatio() {
        let lightGray = PaletteColor(red: 0.8, green: 0.8, blue: 0.8)
        let white = PaletteColor(red: 1.0, green: 1.0, blue: 1.0)

        guard let fixed = sut.suggestFix(for: lightGray, against: white, targetLevel: .aa) else {
            XCTFail("Failed to suggest fix")
            return
        }

        let ratio = fixed.contrastRatio(with: white)
        XCTAssertGreaterThanOrEqual(ratio, Constants.Contrast.aaNormalText)
    }

    func testAssignRolesAssignsBackgroundAndText() {
        let colors = [
            PaletteColor(red: 0.95, green: 0.95, blue: 0.95), // near white
            PaletteColor(red: 0.05, green: 0.05, blue: 0.05), // near black
            PaletteColor(red: 0.8, green: 0.2, blue: 0.2)     // saturated red
        ]

        let assigned = sut.assignRoles(to: colors)

        let bg = assigned.first { $0.role == .background }
        let text = assigned.first { $0.role == .text }
        let accent = assigned.first { $0.role == .accent }

        XCTAssertNotNil(bg)
        XCTAssertNotNil(text)
        XCTAssertNotNil(accent)
    }
}

