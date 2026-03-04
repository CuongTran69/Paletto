import SwiftUI
import Combine

/// ViewModel for the palette extraction screen
final class PaletteExtractionViewModel: ObservableObject {

    @Published var selectedImage: UIImage?
    @Published var extractedColors: [PaletteColor] = []
    @Published var isExtracting = false
    @Published var errorMessage: String?
    @Published var showPhotoPicker = false
    @Published var magnifierPosition: CGPoint?
    @Published var magnifierColor: PaletteColor?
    @Published var showAnalysis = false
    @Published var analysisResult: ImageAnalysisResult?

    private let extractionService: ColorExtractionServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let analysisService: ImageAnalysisServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // Cached pixel data for fast color picking during drag
    private var cachedPixelData: [UInt8]?
    private var cachedImageWidth: Int = 0
    private var cachedImageHeight: Int = 0

    init(
        extractionService: ColorExtractionServiceProtocol = ColorExtractionService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService(),
        analysisService: ImageAnalysisServiceProtocol = ImageAnalysisService()
    ) {
        self.extractionService = extractionService
        self.storageService = storageService
        self.analysisService = analysisService
    }

    // MARK: - Actions

    func onImageSelected(_ image: UIImage) {
        let downsized = image.downsampledToFit(maxDimension: Constants.Image.maxDisplayDimension)
        selectedImage = downsized
        cachePixelData(for: downsized)
        extractColors()
    }

    func extractColors() {
        guard let image = selectedImage else { return }

        isExtracting = true
        errorMessage = nil

        extractionService.extractColors(
            from: image,
            count: SettingsManager.shared.defaultColorCount
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isExtracting = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] colors in
                self?.extractedColors = colors
                self?.triggerHaptic(.success)
            }
        )
        .store(in: &cancellables)
    }

    func pickColor(at normalizedPoint: CGPoint) {
        guard cachedPixelData != nil,
              cachedImageWidth > 0, cachedImageHeight > 0 else { return }

        // Clamp to valid pixel range — normalizedPoint of 1.0 would give x=width (out of bounds)
        let x = min(Int(normalizedPoint.x * CGFloat(cachedImageWidth)), cachedImageWidth - 1)
        let y = min(Int(normalizedPoint.y * CGFloat(cachedImageHeight)), cachedImageHeight - 1)

        guard x >= 0, y >= 0 else { return }

        let bytesPerPixel = 4
        let offset = (y * cachedImageWidth + x) * bytesPerPixel
        let r = CGFloat(cachedPixelData![offset]) / 255.0
        let g = CGFloat(cachedPixelData![offset + 1]) / 255.0
        let b = CGFloat(cachedPixelData![offset + 2]) / 255.0
        let a = CGFloat(cachedPixelData![offset + 3]) / 255.0

        magnifierColor = PaletteColor(red: r, green: g, blue: b, alpha: a)
    }

    // Track which slot to replace when at max capacity (cycles through last 3)
    private var replaceIndex: Int = 0

    func addPickedColor() {
        defer {
            // Always clear magnifier state on release
            magnifierColor = nil
            magnifierPosition = nil
        }

        guard let color = magnifierColor else { return }

        let maxCount = Constants.Palette.maxColorCount
        if extractedColors.count < maxCount {
            // Still have room — append normally
            extractedColors.append(color)
            replaceIndex = 0
        } else {
            // At max capacity — replace last 3 slots in round-robin
            let replaceRange = min(3, maxCount)
            let targetIndex = maxCount - replaceRange + (replaceIndex % replaceRange)
            extractedColors[targetIndex] = color
            replaceIndex += 1
        }
        triggerSelectionHaptic()
    }

    func removeColor(at index: Int) {
        guard extractedColors.indices.contains(index) else { return }
        extractedColors.remove(at: index)
        triggerSelectionHaptic()
    }

    func moveColor(from source: IndexSet, to destination: Int) {
        extractedColors.move(fromOffsets: source, toOffset: destination)
    }

    func savePalette(name: String) -> AnyPublisher<ColorPalette, AppError> {
        let palette = ColorPalette(
            name: name.isEmpty ? L10n.extractionSaveDefault.localized : name,
            colors: extractedColors,
            sourceImageData: selectedImage?.jpegData(compressionQuality: 0.5)
        )

        return storageService.save(palette)
            .map { palette }
            .eraseToAnyPublisher()
    }

    func reset() {
        selectedImage = nil
        extractedColors = []
        magnifierPosition = nil
        magnifierColor = nil
        errorMessage = nil
        cachedPixelData = nil
        cachedImageWidth = 0
        cachedImageHeight = 0
        replaceIndex = 0
    }

    func analyzeImage() {
        guard let image = selectedImage else { return }
        analysisResult = analysisService.analyze(image: image)
        showAnalysis = true
    }

    // MARK: - Private

    /// Cache full pixel buffer once when image is selected — O(1) lookup during drag.
    /// Uses UIGraphicsImageRenderer to bake UIImage orientation into pixel data,
    /// so the cached buffer matches exactly what SwiftUI displays on screen.
    private func cachePixelData(for image: UIImage) {
        // Use the UIImage size (points, orientation-aware) — NOT cgImage dimensions
        // which ignore orientation metadata. This ensures the pixel buffer matches
        // the on-screen rendering by SwiftUI's Image(uiImage:).
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        guard width > 0, height > 0 else { return }

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
              ) else { return }

        // Flip coordinate system — CGContext is bottom-left origin, UIKit is top-left
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // Draw via UIImage (not CGImage) so orientation transforms are applied
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        cachedPixelData = rawData
        cachedImageWidth = width
        cachedImageHeight = height
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func triggerSelectionHaptic() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

