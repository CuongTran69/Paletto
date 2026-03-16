import UIKit

/// Protocol for exporting palettes in various formats
protocol ExportServiceProtocol {
    func exportAsImage(palette: ColorPalette) -> UIImage?
    func exportAsSwiftUI(palette: ColorPalette) -> String
    func exportAsCSS(palette: ColorPalette) -> String
    func exportAsHexList(palette: ColorPalette) -> String
    func exportAsJSONTokens(palette: ColorPalette) -> String
}

