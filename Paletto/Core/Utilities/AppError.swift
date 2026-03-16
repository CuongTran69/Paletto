import Foundation

/// Centralized error type for the app
enum AppError: LocalizedError, Equatable {
    case imageProcessingFailed(String)
    case colorExtractionFailed(String)
    case fileIOError(String)
    case invalidData(String)
    case cameraUnavailable
    case cameraPermissionDenied
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed(let detail):
            return L10n.errorImageProcessing.localized(args: ["detail": detail])
        case .colorExtractionFailed(let detail):
            return L10n.errorColorExtraction.localized(args: ["detail": detail])
        case .fileIOError(let detail):
            return L10n.errorFileIO.localized(args: ["detail": detail])
        case .invalidData(let detail):
            return L10n.errorInvalidData.localized(args: ["detail": detail])
        case .cameraUnavailable:
            return L10n.errorCameraUnavailable.localized
        case .cameraPermissionDenied:
            return L10n.errorCameraPermissionDenied.localized
        case .unknown(let detail):
            return L10n.errorUnknown.localized(args: ["detail": detail])
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraPermissionDenied:
            return L10n.errorRecoveryCameraPermission.localized
        case .cameraUnavailable:
            return L10n.errorRecoveryCameraUnavailable.localized
        default:
            return L10n.errorRecoveryDefault.localized
        }
    }
}

