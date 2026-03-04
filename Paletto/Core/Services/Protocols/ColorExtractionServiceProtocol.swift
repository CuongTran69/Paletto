import UIKit
import Combine

/// Protocol for extracting dominant colors from images
protocol ColorExtractionServiceProtocol {
    /// Extract dominant colors from an image using k-means clustering
    /// - Parameters:
    ///   - image: Source image
    ///   - count: Number of colors to extract (default 5)
    /// - Returns: Publisher emitting array of PaletteColor
    func extractColors(from image: UIImage, count: Int) -> AnyPublisher<[PaletteColor], AppError>

    /// Get the exact color at a specific point in the image
    /// - Parameters:
    ///   - point: Normalized point (0-1 range for both x and y)
    ///   - image: Source image
    /// - Returns: PaletteColor at the specified point
    func pickColor(at point: CGPoint, in image: UIImage) -> Result<PaletteColor, AppError>
}

