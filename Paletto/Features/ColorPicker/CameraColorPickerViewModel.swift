import SwiftUI
import AVFoundation
import Combine

/// ViewModel for camera-based color picking
final class CameraColorPickerViewModel: ObservableObject {

    @Published var currentColor: PaletteColor?
    @Published var pickedColors: [PaletteColor] = []
    @Published var cameraPermission: CameraPermission = .unknown
    @Published var isCameraAvailable = true

    enum CameraPermission {
        case unknown, authorized, denied, restricted
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
        if SettingsManager.shared.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func removeColor(at index: Int) {
        guard pickedColors.indices.contains(index) else { return }
        pickedColors.remove(at: index)
    }

    func updateColor(r: CGFloat, g: CGFloat, b: CGFloat) {
        currentColor = PaletteColor(red: r, green: g, blue: b)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

