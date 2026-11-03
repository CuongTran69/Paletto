import SwiftUI
import AVFoundation

/// ViewModel for camera-based color picking
@MainActor
final class CameraColorPickerViewModel: ObservableObject {

    @Published var currentColor: PaletteColor?
    @Published var pickedColors: [PaletteColor] = []
    @Published var cameraPermission: CameraPermission = .unknown
    @Published var isCameraAvailable = true

    var undoManager: UndoManager?

    private let storageService: PaletteStorageServiceProtocol
    private let settingsManager: SettingsManagerProtocol

    enum CameraPermission {
        case unknown, authorized, denied, restricted
    }

    init(
        storageService: PaletteStorageServiceProtocol = PaletteStorageService.shared,
        settingsManager: SettingsManagerProtocol = SettingsManager.shared
    ) {
        self.storageService = storageService
        self.settingsManager = settingsManager
    }

    func checkPermission() {
        #if targetEnvironment(simulator)
        isCameraAvailable = false
        return
        #endif

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermission = granted ? .authorized : .denied
                }
            }
        case .denied:
            cameraPermission = .denied
        case .restricted:
            cameraPermission = .restricted
        @unknown default:
            cameraPermission = .denied
        }
    }

    func addCurrentColor() {
        guard let color = currentColor else { return }
        guard pickedColors.count < Constants.Palette.maxColorCount else { return }
        pickedColors.append(color)
        undoManager?.performUndoGroup(L10n.libraryUndoAddColor.localized) { [weak self] in
            self?.pickedColors.removeLast()
        }
        if settingsManager.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func removeColor(at index: Int) {
        guard pickedColors.indices.contains(index) else { return }
        let removedColor = pickedColors[index]
        pickedColors.remove(at: index)
        undoManager?.performUndoGroup(L10n.libraryUndoRemoveColor.localized) { [weak self] in
            guard let self else { return }
            self.pickedColors.insert(removedColor, at: min(index, self.pickedColors.count))
        }
    }

    func updateColor(r: CGFloat, g: CGFloat, b: CGFloat) {
        currentColor = PaletteColor(red: r, green: g, blue: b)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func savePalette(name: String) async throws -> ColorPalette {
        let palette = ColorPalette(
            name: name.isEmpty ? L10n.cameraSaveDefault.localized : name,
            colors: pickedColors
        )
        try await storageService.save(palette)
        return palette
    }
}

