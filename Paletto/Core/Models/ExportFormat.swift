import Foundation

/// Supported export formats for palettes
enum ExportFormat: String, CaseIterable, Identifiable {
    case image
    case swiftUI
    case css
    case tailwind
    case compose
    case flutter
    case svg
    case hexList
    case jsonTokens

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .image: return L10n.exportFormatImage.localized
        case .swiftUI: return L10n.exportFormatSwiftUI.localized
        case .css: return L10n.exportFormatCSS.localized
        case .tailwind: return L10n.exportFormatTailwind.localized
        case .compose: return L10n.exportFormatCompose.localized
        case .flutter: return L10n.exportFormatFlutter.localized
        case .svg: return L10n.exportFormatSvg.localized
        case .hexList: return L10n.exportFormatHexList.localized
        case .jsonTokens: return L10n.exportFormatJSONTokens.localized
        }
    }

    var iconName: String {
        switch self {
        case .image: return "photo"
        case .swiftUI: return "swift"
        case .css: return "chevron.left.forwardslash.chevron.right"
        case .tailwind: return "wind"
        case .compose: return "shippingbox"
        case .flutter: return "app.dashed"
        case .svg: return "square.on.circle"
        case .hexList: return "list.bullet"
        case .jsonTokens: return "curlybraces"
        }
    }

    var fileExtension: String {
        switch self {
        case .image: return "png"
        case .swiftUI: return "swift"
        case .css: return "css"
        case .tailwind: return "js"
        case .compose: return "kt"
        case .flutter: return "dart"
        case .svg: return "svg"
        case .hexList: return "txt"
        case .jsonTokens: return "json"
        }
    }

    var mimeType: String {
        switch self {
        case .image: return "image/png"
        case .swiftUI: return "text/plain"
        case .css: return "text/css"
        case .tailwind: return "application/javascript"
        case .compose: return "text/plain"
        case .flutter: return "text/plain"
        case .svg: return "image/svg+xml"
        case .hexList: return "text/plain"
        case .jsonTokens: return "application/json"
        }
    }
}

