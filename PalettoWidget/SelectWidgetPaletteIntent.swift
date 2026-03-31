import AppIntents
import WidgetKit

// Widget-local copy of SelectWidgetPaletteIntent so the extension can reference it.
// The main app's SelectWidgetPaletteIntent.perform() writes to the shared UserDefaults
// that this extension reads via PaletteTimelineProvider.

@available(iOSApplicationExtension 17.0, *)
struct ColorPaletteEntityWidget: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Palette"

    let id: UUID
    let name: String
    let hexColorCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) — \(hexColorCount) colors")
    }

    static var defaultQuery = PaletteQueryWidget()
}

@available(iOSApplicationExtension 17.0, *)
struct PaletteQueryWidget: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ColorPaletteEntityWidget] {
        let all = try await PaletteStorageServiceWidget.shared.loadAll()
        return all
            .filter { identifiers.contains($0.id) }
            .map { ColorPaletteEntityWidget(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func suggestedEntities() async throws -> [ColorPaletteEntityWidget] {
        let all = try await PaletteStorageServiceWidget.shared.loadAll()
        return all
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { ColorPaletteEntityWidget(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func defaultResult() async -> ColorPaletteEntityWidget? { nil }
}

// Minimal ColorPalette for widget entity query (read-only, same format as main app)
@available(iOSApplicationExtension 17.0, *)
private struct ColorPaletteWidget: Codable {
    let id: UUID
    let name: String
    let colors: [PaletteColorWidget]

    struct PaletteColorWidget: Codable {
        let id: UUID
        let hex: String
        let role: String?
    }
}

// Minimal storage service for widget entity query
@available(iOSApplicationExtension 17.0, *)
private final class PaletteStorageServiceWidget {
    static let shared = PaletteStorageServiceWidget()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var palettesDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("Palettes")
    }

    func loadAll() async throws -> [ColorPaletteWidget] {
        let files = try FileManager.default.contentsOfDirectory(
            at: palettesDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try files.compactMap { url -> ColorPaletteWidget? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(ColorPaletteWidget.self, from: data)
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
enum WidgetSizeEntityWidget: String, AppEnum {
    case small
    case medium
    case large

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Size"

    static var caseDisplayRepresentations: [WidgetSizeEntityWidget: DisplayRepresentation] = [
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

@available(iOSApplicationExtension 17.0, *)
struct SelectWidgetPaletteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Palette"
    static var description: IntentDescription? = "Choose a palette for your Paletto widget"

    @Parameter(title: "Palette")
    var selectedPalette: ColorPaletteEntityWidget

    @Parameter(title: "Widget Size")
    var widgetSize: WidgetSizeEntityWidget

    init() {}

    init(selectedPalette: ColorPaletteEntityWidget, widgetSize: WidgetSizeEntityWidget) {
        self.selectedPalette = selectedPalette
        self.widgetSize = widgetSize
    }

    func perform() async throws -> some IntentResult {
        let kind = widgetSize.toKind
        let key = "widget_\(kind.rawValue)"

        let isoFormatter = ISO8601DateFormatter()
        let paletteDict: [String: Any] = [
            "id": selectedPalette.id.uuidString,
            "name": selectedPalette.name,
            "hexColors": [],
            "colorRoles": []
        ]

        let configDict: [String: Any] = [
            "palette": paletteDict,
            "updatedAt": isoFormatter.string(from: Date())
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: configDict, options: []) else {
            return .result()
        }

        let sharedDefaults = UserDefaults(suiteName: "group.com.paletto.shared")
        sharedDefaults?.set(data, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")

        return .result()
    }
}
