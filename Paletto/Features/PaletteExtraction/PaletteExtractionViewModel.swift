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

    var undoManager: UndoManager?

    private let extractionService: ColorExtractionServiceProtocol
    private let storageService: PaletteStorageServiceProtocol
    private let analysisService: ImageAnalysisServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    // Cached pixel data for fast color picking during drag
    private var cachedPixelData: [UInt8]?
    private var cachedImageWidth: Int = 0
    private var cachedImageHeight: Int = 0

    // Track which slot to replace when at max capacity (cycles through last 3)
    private var replaceIndex: Int = 0

    init(
        extractionService: ColorExtractionServiceProtocol = ColorExtractionService(),
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared,
        analysisService: ImageAnalysisServiceProtocol = ImageAnalysisService(),
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.extractionService = extractionService
        self.storageService = storageService
        self.analysisService = analysisService
        self.settingsManager = settingsManager
    }

    // MARK: - Actions

    func onImageSelected(_ image: UIImage) {
        let downsized = image.downsampledToFit(maxDimension: Constants.Image.maxDisplayDimension)
        selectedImage = downsized
        Task { await cachePixelData(for: downsized) }
        extractColors()
    }

    func extractColors() {
        guard let image = selectedImage else { return }

        isExtracting = true
        errorMessage = nil

        Task {
            do {
                let colors = try await extractionService.extractColors(
                    from: image,
                    count: settingsManager.defaultColorCount
                )
                self.extractedColors = colors
                self.triggerHaptic(.success)
            } catch let error as AppError {
                self.errorMessage = error.localizedDescription
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isExtracting = false
        }
    }

    func pickColor(at normalizedPoint: CGPoint) {
        guard cachedPixelData != nil,
              cachedImageWidth > 0, cachedImageHeight > 0 else { return }

        let x = min(Int(normalizedPoint.x * CGFloat(cachedImageWidth)), cachedImageWidth - 1)
        let y = min(Int(normalizedPoint.y * CGFloat(cachedImageHeight)), cachedImageHeight - 1)

        guard x >= 0, y >= 0 else { return }

        let bytesPerPixel = 4
        let offset = (y * cachedImageWidth + x) * bytesPerPixel

        guard offset + bytesPerPixel - 1 < cachedPixelData!.count else { return }

        let r = CGFloat(cachedPixelData![offset]) / 255.0
        let g = CGFloat(cachedPixelData![offset + 1]) / 255.0
        let b = CGFloat(cachedPixelData![offset + 2]) / 255.0
        let a = CGFloat(cachedPixelData![offset + 3]) / 255.0

        magnifierColor = PaletteColor(red: r, green: g, blue: b, alpha: a)
    }

    func addPickedColor() {
        defer {
            magnifierColor = nil
            magnifierPosition = nil
        }

        guard let color = magnifierColor else { return }

        let maxCount = Constants.Palette.maxColorCount

        if extractedColors.count < maxCount {
            let colorToAdd = color
            extractedColors.append(colorToAdd)
            replaceIndex = 0

            // Register undo: remove the added color
            undoManager?.performUndoGroup(L10n.libraryUndoAddColor.localized) { [weak self] in
                self?.extractedColors.removeLast()
            }
        } else {
            // At max capacity — replace last 3 slots in round-robin
            let replaceRange = min(3, maxCount)
            let targetIndex = maxCount - replaceRange + (replaceIndex % replaceRange)
            let previousColor = extractedColors[targetIndex]
            extractedColors[targetIndex] = color
            replaceIndex += 1

            // Register undo: restore the previous color
            undoManager?.performUndoGroup(L10n.libraryUndoAddColor.localized) { [weak self] in
                guard let self, self.extractedColors.indices.contains(targetIndex) else { return }
                self.extractedColors[targetIndex] = previousColor
            }
        }
        triggerSelectionHaptic()
    }

    func removeColor(at index: Int) {
        guard extractedColors.indices.contains(index) else { return }
        let removedColor = extractedColors[index]
        extractedColors.remove(at: index)
        triggerSelectionHaptic()

        // Register undo: restore the removed color
        undoManager?.performUndoGroup(L10n.libraryUndoRemoveColor.localized) { [weak self] in
            guard let self else { return }
            self.extractedColors.insert(removedColor, at: min(index, self.extractedColors.count))
        }
    }

    func moveColor(from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }

        // Capture previous state for undo
        let previousColors = extractedColors

        extractedColors.move(fromOffsets: source, toOffset: destination)

        // Register undo: restore previous order
        undoManager?.performUndoGroup(L10n.libraryUndoReorderColors.localized) { [weak self] in
            self?.extractedColors = previousColors
        }
    }

    func savePalette(name: String) async throws -> ColorPalette {
        let palette = ColorPalette(
            name: name.isEmpty ? L10n.extractionSaveDefault.localized : name,
            colors: extractedColors,
            sourceImageData: selectedImage?.jpegData(compressionQuality: 0.5)
        )

        try await storageService.save(palette)
        return palette
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

    private func cachePixelData(for image: UIImage) async {
        guard let result = await Self.buildPixelData(for: image) else { return }
        cachedPixelData = result.data
        cachedImageWidth = result.width
        cachedImageHeight = result.height
    }

    private nonisolated static func buildPixelData(for image: UIImage) async -> (data: [UInt8], width: Int, height: Int)? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

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
              ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (rawData, width, height)
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func triggerSelectionHaptic() {
        guard settingsManager.hapticFeedbackEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
