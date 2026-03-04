import UIKit
import CoreImage.CIFilterBuiltins

/// Generates QR code images from strings using CoreImage
enum QRCodeGenerator {

    /// Generate a QR code UIImage from a string
    /// - Parameters:
    ///   - string: The content to encode
    ///   - size: The desired output size (points)
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    static func generate(from string: String, size: CGFloat = 200) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        // Scale up from tiny CIImage to desired size
        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

