import Foundation
import WidgetKit

/// Lightweight palette data for widget display (no sourceImageData)
struct WidgetPalette: Codable {
    let id: String
    let name: String
    let hexColors: [String]
    let colorRoles: [String?]

    init(palette: ColorPalette) {
        self.id = palette.id.uuidString
        self.name = palette.name
        self.hexColors = palette.colors.map { $0.hex }
        self.colorRoles = palette.colors.map { $0.role?.rawValue }
    }
}

/// Manages shared data between main app and widget extension via App Group
final class SharedDataService {

    static let shared = SharedDataService()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var sharedDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier)
        if defaults == nil {
            print("[SharedDataService] ⚠️ App Group '\(Constants.Storage.appGroupIdentifier)' not available. Ensure App Group is enabled in Signing & Capabilities for both targets.")
        }
        return defaults
    }

    private init() {}

    // MARK: - Widget Palette (per-size slot)

    /// Save a palette to the shared container for a specific widget size slot
    func setWidgetPalette(_ palette: ColorPalette, forKind kind: WidgetKind) {
        let widgetPalette = WidgetPalette(palette: palette)
        let config = WidgetConfig(palette: widgetPalette, updatedAt: Date())
        guard let data = try? encoder.encode(config) else {
            print("[SharedDataService] ⚠️ Failed to encode widget config")
            return
        }

        let key = Constants.Storage.widgetSlotKey(for: kind)
        if let defaults = sharedDefaults {
            defaults.set(data, forKey: key)
        } else {
            // Fallback: save to standard UserDefaults so data is at least persisted in the app
            UserDefaults.standard.set(data, forKey: key)
            print("[SharedDataService] ⚠️ Saved to standard UserDefaults as fallback (widget won't read this)")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")
    }

    /// Load the widget palette for a specific widget size slot from shared container
    func getWidgetPalette(forKind kind: WidgetKind) -> WidgetPalette? {
        let key = Constants.Storage.widgetSlotKey(for: kind)
        let data: Data?
        if let defaults = sharedDefaults {
            data = defaults.data(forKey: key)
        } else {
            // Fallback: try standard UserDefaults
            data = UserDefaults.standard.data(forKey: key)
        }
        guard let data else { return nil }
        let config = try? decoder.decode(WidgetConfig.self, from: data)
        return config?.palette
    }
}

