import Foundation
import WidgetKit

/// Lightweight palette data for widget display (no sourceImageData)
struct WidgetPalette: Codable {
    let id: String
    let name: String
    let hexColors: [String]

    init(palette: ColorPalette) {
        self.id = palette.id.uuidString
        self.name = palette.name
        self.hexColors = palette.colors.map { $0.hex }
    }
}

/// Manages shared data between main app and widget extension via App Group
final class SharedDataService {

    static let shared = SharedDataService()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    private let decoder = JSONDecoder()

    private var sharedDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier)
        if defaults == nil {
            print("[SharedDataService] ⚠️ App Group '\(Constants.Storage.appGroupIdentifier)' not available. Ensure App Group is enabled in Signing & Capabilities for both targets.")
        }
        return defaults
    }

    private init() {}

    // MARK: - Widget Palette

    /// Save a palette to the shared container for widget display
    func setWidgetPalette(_ palette: ColorPalette) {
        let widgetPalette = WidgetPalette(palette: palette)
        guard let data = try? encoder.encode(widgetPalette) else {
            print("[SharedDataService] ⚠️ Failed to encode widget palette")
            return
        }

        if let defaults = sharedDefaults {
            defaults.set(data, forKey: Constants.Storage.widgetPaletteKey)
        } else {
            // Fallback: save to standard UserDefaults so data is at least persisted in the app
            UserDefaults.standard.set(data, forKey: Constants.Storage.widgetPaletteKey)
            print("[SharedDataService] ⚠️ Saved to standard UserDefaults as fallback (widget won't read this)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Load the widget palette from shared container
    func getWidgetPalette() -> WidgetPalette? {
        let data: Data?
        if let defaults = sharedDefaults {
            data = defaults.data(forKey: Constants.Storage.widgetPaletteKey)
        } else {
            // Fallback: try standard UserDefaults
            data = UserDefaults.standard.data(forKey: Constants.Storage.widgetPaletteKey)
        }
        guard let data else { return nil }
        return try? decoder.decode(WidgetPalette.self, from: data)
    }
}

