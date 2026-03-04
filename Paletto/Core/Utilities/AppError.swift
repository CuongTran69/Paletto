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
            return "Image processing failed: \(detail)"
        case .colorExtractionFailed(let detail):
            return "Color extraction failed: \(detail)"
        case .fileIOError(let detail):
            return "File error: \(detail)"
        case .invalidData(let detail):
            return "Invalid data: \(detail)"
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .cameraPermissionDenied:
            return "Camera access was denied. Please enable it in Settings."
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Go to Settings > Paletto > Camera to enable access."
        case .cameraUnavailable:
            return "Try using the photo picker instead."
        default:
            return "Please try again."
        }
    }
}

