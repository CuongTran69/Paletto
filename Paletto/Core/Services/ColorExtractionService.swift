import UIKit
import Combine

/// Extracts dominant colors from images using k-means clustering in CIE LAB color space
final class ColorExtractionService: ColorExtractionServiceProtocol {

    private let processingQueue = DispatchQueue(
        label: "com.paletto.colorExtraction",
        qos: .userInitiated
    )

    // MARK: - Public API

    func extractColors(from image: UIImage, count: Int) -> AnyPublisher<[PaletteColor], AppError> {
        Future<[PaletteColor], AppError> { [weak self] promise in
            guard let self else {
                promise(.failure(.colorExtractionFailed("Service deallocated")))
                return
            }
            self.processingQueue.async {
                let result = self.performExtraction(from: image, count: count)
                DispatchQueue.main.async {
                    promise(result)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func pickColor(at point: CGPoint, in image: UIImage) -> Result<PaletteColor, AppError> {
        guard let cgImage = image.cgImage else {
            return .failure(.imageProcessingFailed("Cannot access image data"))
        }

        let pixelX = point.x * CGFloat(cgImage.width)
        let pixelY = point.y * CGFloat(cgImage.height)

        guard let rgba = image.pixelColor(at: CGPoint(x: pixelX, y: pixelY)) else {
            return .failure(.colorExtractionFailed("Cannot read pixel at (\(pixelX), \(pixelY))"))
        }

        let color = PaletteColor(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
        return .success(color)
    }

    // MARK: - Private

    private func performExtraction(from image: UIImage, count: Int) -> Result<[PaletteColor], AppError> {
        // Step 1: Downsample
        let targetSize = CGSize(
            width: Constants.Image.downsampleSize,
            height: Constants.Image.downsampleSize
        )
        guard let resized = image.resized(to: targetSize) else {
            return .failure(.imageProcessingFailed("Failed to downsample image"))
        }

        // Step 2: Get pixel data
        guard let pixels = resized.pixelData() else {
            return .failure(.imageProcessingFailed("Failed to read pixel data"))
        }

        // Step 3: Convert to LAB
        let labPixels = pixels.map { px -> CIELABColor in
            let pc = PaletteColor(red: px.r, green: px.g, blue: px.b)
            return pc.labColor
        }

        // Step 4: Filter near-black and near-white
        let filtered = labPixels.filter { lab in
            lab.l > 5 && lab.l < 95
        }

        let dataToCluster = filtered.isEmpty ? labPixels : filtered

        // Step 5: Run k-means multiple times, pick best
        var bestCentroids: [CIELABColor] = []
        var bestScore = CGFloat.infinity

        for _ in 0..<Constants.Image.kMeansRuns {
            let (centroids, score) = kMeans(
                data: dataToCluster,
                k: count,
                maxIterations: Constants.Image.kMeansMaxIterations
            )
            if score < bestScore {
                bestScore = score
                bestCentroids = centroids
            }
        }

        // Step 6: Convert back to PaletteColor, sort by luminance
        let colors = bestCentroids
            .map { PaletteColor.fromLAB($0) }
            .sorted { $0.relativeLuminance > $1.relativeLuminance }

        return .success(colors)
    }
}

// MARK: - K-Means Clustering

extension ColorExtractionService {

    /// K-means++ initialization: pick initial centroids spread apart
    private func kMeansPlusPlusInit(data: [CIELABColor], k: Int) -> [CIELABColor] {
        guard !data.isEmpty else { return [] }

        var centroids: [CIELABColor] = []

        // Pick first centroid randomly
        let firstIndex = Int.random(in: 0..<data.count)
        centroids.append(data[firstIndex])

        // Pick remaining centroids weighted by distance
        for _ in 1..<k {
            let distances = data.map { point -> CGFloat in
                centroids.map { point.distance(to: $0) }.min() ?? 0
            }
            let totalDistance = distances.reduce(0, +)
            guard totalDistance > 0 else { break }

            var target = CGFloat.random(in: 0..<totalDistance)
            var selectedIndex = 0
            for (index, dist) in distances.enumerated() {
                target -= dist
                if target <= 0 {
                    selectedIndex = index
                    break
                }
            }
            centroids.append(data[selectedIndex])
        }

        return centroids
    }

    /// Run k-means clustering, returns (centroids, total distance score)
    private func kMeans(
        data: [CIELABColor],
        k: Int,
        maxIterations: Int
    ) -> ([CIELABColor], CGFloat) {
        guard data.count >= k else {
            return (data, 0)
        }

        var centroids = kMeansPlusPlusInit(data: data, k: k)
        var assignments = [Int](repeating: 0, count: data.count)

        for _ in 0..<maxIterations {
            // Assignment step: assign each point to nearest centroid
            var changed = false
            for (i, point) in data.enumerated() {
                var minDist = CGFloat.infinity
                var minIndex = 0
                for (j, centroid) in centroids.enumerated() {
                    let dist = point.distance(to: centroid)
                    if dist < minDist {
                        minDist = dist
                        minIndex = j
                    }
                }
                if assignments[i] != minIndex {
                    assignments[i] = minIndex
                    changed = true
                }
            }

            if !changed { break }

            // Update step: recalculate centroids
            for j in 0..<k {
                let clusterPoints = data.enumerated()
                    .filter { assignments[$0.offset] == j }
                    .map { $0.element }

                guard !clusterPoints.isEmpty else { continue }

                let count = CGFloat(clusterPoints.count)
                let avgL = clusterPoints.map(\.l).reduce(0, +) / count
                let avgA = clusterPoints.map(\.a).reduce(0, +) / count
                let avgB = clusterPoints.map(\.b).reduce(0, +) / count
                centroids[j] = CIELABColor(l: avgL, a: avgA, b: avgB)
            }
        }

        // Calculate total distance score
        let totalDistance = data.enumerated().reduce(CGFloat(0)) { sum, pair in
            sum + pair.element.distance(to: centroids[assignments[pair.offset]])
        }

        return (centroids, totalDistance)
    }
}

