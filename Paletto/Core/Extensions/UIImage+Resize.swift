import UIKit

extension UIImage {
    /// Downsample image so the longest side fits within maxDimension, preserving aspect ratio.
    /// Returns the original image unchanged if already within bounds.
    func downsampledToFit(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )
        return resized(to: newSize) ?? self
    }

    /// Resize image to target size using high-quality interpolation
    func resized(to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Get the color at a specific pixel coordinate
    /// - Parameter point: Point in image coordinates (not normalized)
    /// - Returns: RGBA components (0-1 range)
    func pixelColor(at point: CGPoint) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        guard let cgImage = cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let x = Int(point.x)
        let y = Int(point.y)

        guard x >= 0, x < width, y >= 0, y < height else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: 4)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: 1,
                  height: 1,
                  bitsPerComponent: bitsPerComponent,
                  bytesPerRow: bytesPerPixel,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.draw(
            cgImage,
            in: CGRect(
                x: -CGFloat(x),
                y: -CGFloat(y),
                width: CGFloat(width),
                height: CGFloat(height)
            )
        )

        let r = CGFloat(pixelData[0]) / 255.0
        let g = CGFloat(pixelData[1]) / 255.0
        let b = CGFloat(pixelData[2]) / 255.0
        let a = CGFloat(pixelData[3]) / 255.0

        return (r, g, b, a)
    }

    /// Get raw pixel data as array of (r, g, b) tuples (0-1 range)
    func pixelData() -> [(r: CGFloat, g: CGFloat, b: CGFloat)]? {
        guard let cgImage = cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height

        var rawData = [UInt8](repeating: 0, count: totalBytes)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &rawData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pixels: [(r: CGFloat, g: CGFloat, b: CGFloat)] = []
        pixels.reserveCapacity(width * height)

        for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
            let r = CGFloat(rawData[i]) / 255.0
            let g = CGFloat(rawData[i + 1]) / 255.0
            let b = CGFloat(rawData[i + 2]) / 255.0
            pixels.append((r, g, b))
        }

        return pixels
    }
}

