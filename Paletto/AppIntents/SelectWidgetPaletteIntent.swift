import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct ColorPaletteEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Palette"

    let id: UUID
    let name: String
    let hexColorCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) — \(hexColorCount) colors")
    }

    static var defaultQuery = PaletteQuery()
}

// MARK: - Palette Query

@available(iOS 17.0, *)
struct PaletteQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ColorPaletteEntity] {
        let all = try await PaletteStorageService.shared.loadAll()
        return all
            .filter { identifiers.contains($0.id) }
            .map { ColorPaletteEntity(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func suggestedEntities() async throws -> [ColorPaletteEntity] {
        let all = try await PaletteStorageService.shared.loadAll()
        return all
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { ColorPaletteEntity(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func defaultResult() async -> ColorPaletteEntity? {
        nil
    }
}

// MARK: - Widget Size Entity

@available(iOS 17.0, *)
enum WidgetSizeEntity: String, AppEnum {
    case small
    case medium
    case large

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Size"

    static var caseDisplayRepresentations: [WidgetSizeEntity: DisplayRepresentation] = [
        .small: DisplayRepresentation(title: "Small"),
        .medium: DisplayRepresentation(title: "Medium"),
        .large: DisplayRepresentation(title: "Large")
    ]

    var toKind: WidgetKind {
        switch self {
        case .small:  return .small
        case .medium: return .medium
        case .large:  return .large
        }
    }
}

// MARK: - Select Widget Palette Intent

@available(iOS 17.0, *)
struct SelectWidgetPaletteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Palette"
    static var description: IntentDescription? = "Choose a palette for your Paletto widget"

    @Parameter(title: "Palette")
    var selectedPalette: ColorPaletteEntity

    @Parameter(title: "Widget Size")
    var widgetSize: WidgetSizeEntity

    init() {}

    init(selectedPalette: ColorPaletteEntity, widgetSize: WidgetSizeEntity) {
        self.selectedPalette = selectedPalette
        self.widgetSize = widgetSize
    }

    func perform() async throws -> some IntentResult {
        // Load full palette from storage
        guard let palette = try await PaletteStorageService.shared.load(id: selectedPalette.id) else {
            return .result()
        }

        let kind = widgetSize.toKind
        let key = "widget_\(kind.rawValue)"

        // Build WidgetConfigData-compatible JSON dict (widget extension reads WidgetConfigData directly)
        // Widget uses JSONDecoder with dateDecodingStrategy = .iso8601
        let isoFormatter = ISO8601DateFormatter()

        // Build the nested palette dict
        let paletteDict: [String: Any] = [
            "id": palette.id.uuidString,
            "name": palette.name,
            "hexColors": palette.colors.map { $0.hex },
            "colorRoles": palette.colors.map { $0.role?.rawValue as Any }
        ]

        let configDict: [String: Any] = [
            "palette": paletteDict,
            "updatedAt": isoFormatter.string(from: Date())
        ]

        // Serialize to JSON Data
        guard let data = try? JSONSerialization.data(withJSONObject: configDict, options: []) else {
            return .result()
        }

        let sharedDefaults = UserDefaults(suiteName: "group.com.paletto.shared")
        sharedDefaults?.set(data, forKey: key)

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")

        return .result()
    }
}
