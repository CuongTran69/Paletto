import Foundation

/// Supported export formats for palettes
enum ExportFormat: String, CaseIterable, Identifiable {
    case image
    case swiftUI
    case css
    case hexList
    case jsonTokens

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .image: return "export.format.image".localized
        case .swiftUI: return "export.format.swiftui".localized
        case .css: return "export.format.css".localized
        case .hexList: return "export.format.hexlist".localized
        case .jsonTokens: return "export.format.jsontokens".localized
        }
    }

    var iconName: String {
        switch self {
        case .image: return "photo"
        case .swiftUI: return "swift"
        case .css: return "chevron.left.forwardslash.chevron.right"
        case .hexList: return "list.bullet"
        case .jsonTokens: return "curlybraces"
        }
    }

    var fileExtension: String {
        switch self {
        case .image: return "png"
        case .swiftUI: return "swift"
        case .css: return "css"
        case .hexList: return "txt"
        case .jsonTokens: return "json"
        }
    }

    var mimeType: String {
        switch self {
        case .image: return "image/png"
        case .swiftUI: return "text/plain"
        case .css: return "text/css"
        case .hexList: return "text/plain"
        case .jsonTokens: return "application/json"
        }
    }
}

