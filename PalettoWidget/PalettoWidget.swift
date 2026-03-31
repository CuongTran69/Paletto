import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Constants (duplicated for widget target independence)

private let appGroupIdentifier = "group.com.paletto.shared"

/// Widget size kind — duplicated here because widget extension cannot import main app code
enum WidgetKind: String, Codable, CaseIterable {
    case small
    case medium
    case large
}

/// Lightweight palette data matching main app's WidgetPalette
struct WidgetPaletteData: Codable {
    let id: String
    let name: String
    let hexColors: [String]
    let colorRoles: [String?]
}

/// Widget-local equivalent of WidgetConfig
struct WidgetConfigData: Codable {
    let palette: WidgetPaletteData?
    let updatedAt: Date
}

// MARK: - Safe subscript for optional String arrays

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// Parse hex string to Color
func colorFromHex(_ hex: String) -> Color {
    let clean = hex.replacingOccurrences(of: "#", with: "")
    guard clean.count == 6 else { return .gray }
    var rgb: UInt64 = 0
    Scanner(string: clean).scanHexInt64(&rgb)
    return Color(
        red: Double((rgb >> 16) & 0xFF) / 255.0,
        green: Double((rgb >> 8) & 0xFF) / 255.0,
        blue: Double(rgb & 0xFF) / 255.0
    )
}

// MARK: - Timeline

struct PaletteEntry: TimelineEntry {
    let date: Date
    let palette: WidgetPaletteData?
}

struct PaletteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PaletteEntry {
        PaletteEntry(date: .now, palette: WidgetPaletteData(
            id: "preview",
            name: "My Palette",
            hexColors: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"],
            colorRoles: ["Background", "Primary", "Secondary", "Accent", "Text"]
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (PaletteEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PaletteEntry>) -> Void) {
        let kind: WidgetKind
        switch context.family {
        case .systemSmall:  kind = .small
        case .systemMedium: kind = .medium
        case .systemLarge:  kind = .large
        default:            kind = .small
        }
        let palette = loadWidgetPaletteData(forKind: kind)
        let entry = PaletteEntry(date: .now, palette: palette)
        // Refresh every 30 minutes (in case user changes widget palette)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWidgetPaletteData(forKind kind: WidgetKind) -> WidgetPaletteData? {
        let key = "widget_\(kind.rawValue)"
        let data: Data?
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            data = defaults.data(forKey: key)
        } else {
            // Fallback: try standard UserDefaults (only works if widget and app share same sandbox, unlikely)
            data = UserDefaults.standard.data(forKey: key)
            print("[PalettoWidget] ⚠️ App Group not available, tried standard UserDefaults as fallback")
        }
        guard let data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let config = try? decoder.decode(WidgetConfigData.self, from: data)
        return config?.palette
    }
}

// MARK: - AppIntents for Widget Configuration (iOS 17+)

// Minimal ColorPalette for entity query (read-only)
private struct ColorPaletteQueryItem: Codable {
    let id: UUID
    let name: String
    let colors: [PaletteColorQueryItem]

    struct PaletteColorQueryItem: Codable {
        let id: UUID
        let hex: String
        let role: String?
    }
}

// Minimal storage for entity query
private final class PaletteQueryStorage {
    static let shared = PaletteQueryStorage()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var palettesDirectory: URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return container.appendingPathComponent("Palettes")
    }

    func loadAll() async throws -> [ColorPaletteQueryItem] {
        let files = try FileManager.default.contentsOfDirectory(
            at: palettesDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try files.compactMap { url -> ColorPaletteQueryItem? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(ColorPaletteQueryItem.self, from: data)
        }
    }

    func loadById(_ id: UUID) async throws -> ColorPaletteQueryItem? {
        let url = palettesDirectory.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(ColorPaletteQueryItem.self, from: data)
    }
}

// MARK: - Widget Size Entity

@available(iOSApplicationExtension 17.0, *)
enum WidgetSizeIntentEnum: String, AppEnum {
    case small
    case medium
    case large

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Size"

    static var caseDisplayRepresentations: [WidgetSizeIntentEnum: DisplayRepresentation] = [
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

// MARK: - Color Palette Entity

@available(iOSApplicationExtension 17.0, *)
struct ColorPaletteIntentEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Palette"

    let id: UUID
    let name: String
    let hexColorCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) — \(hexColorCount) colors")
    }

    static var defaultQuery = PaletteIntentQuery()
}

@available(iOSApplicationExtension 17.0, *)
struct PaletteIntentQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ColorPaletteIntentEntity] {
        let all = try await PaletteQueryStorage.shared.loadAll()
        return all
            .filter { identifiers.contains($0.id) }
            .map { ColorPaletteIntentEntity(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func suggestedEntities() async throws -> [ColorPaletteIntentEntity] {
        let all = try await PaletteQueryStorage.shared.loadAll()
        return all
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { ColorPaletteIntentEntity(id: $0.id, name: $0.name, hexColorCount: $0.colors.count) }
    }

    func defaultResult() async -> ColorPaletteIntentEntity? { nil }
}

// MARK: - Select Widget Palette Intent

@available(iOSApplicationExtension 17.0, *)
struct SelectWidgetPaletteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Palette"
    static var description: IntentDescription? = "Choose a palette for your Paletto widget"

    @Parameter(title: "Palette")
    var selectedPalette: ColorPaletteIntentEntity

    @Parameter(title: "Widget Size")
    var widgetSize: WidgetSizeIntentEnum

    init() {}

    init(selectedPalette: ColorPaletteIntentEntity, widgetSize: WidgetSizeIntentEnum) {
        self.selectedPalette = selectedPalette
        self.widgetSize = widgetSize
    }

    func perform() async throws -> some IntentResult {
        // Load the full palette from disk to get actual hex/role data
        guard let fullPalette = try await PaletteQueryStorage.shared.loadById(selectedPalette.id) else {
            return .result()
        }

        let kind = widgetSize.toKind
        let widgetPalette = WidgetPaletteData(
            id: selectedPalette.id.uuidString,
            name: selectedPalette.name,
            hexColors: fullPalette.colors.map { $0.hex },
            colorRoles: fullPalette.colors.map { $0.role }
        )

        let config = WidgetConfigData(palette: widgetPalette, updatedAt: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(config) else {
            return .result()
        }

        let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        sharedDefaults?.set(data, forKey: "widget_\(kind.rawValue)")
        WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")

        return .result()
    }
}

// MARK: - AppIntent Timeline Provider

@available(iOSApplicationExtension 17.0, *)
struct PaletteAppIntentTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PaletteEntry {
        PaletteEntry(date: .now, palette: WidgetPaletteData(
            id: "preview",
            name: "My Palette",
            hexColors: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"],
            colorRoles: ["Background", "Primary", "Secondary", "Accent", "Text"]
        ))
    }

    func snapshot(for configuration: SelectWidgetPaletteIntent, in context: Context) async -> PaletteEntry {
        let kind: WidgetKind
        switch context.family {
        case .systemSmall:  kind = .small
        case .systemMedium: kind = .medium
        case .systemLarge:  kind = .large
        default:            kind = .small
        }
        let palette = loadPaletteData(forKind: kind)
        return PaletteEntry(date: .now, palette: palette)
    }

    func timeline(for configuration: SelectWidgetPaletteIntent, in context: Context) async -> Timeline<PaletteEntry> {
        let kind: WidgetKind
        switch context.family {
        case .systemSmall:  kind = .small
        case .systemMedium: kind = .medium
        case .systemLarge:  kind = .large
        default:            kind = .small
        }
        let palette = loadPaletteData(forKind: kind)
        let entry = PaletteEntry(date: .now, palette: palette)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadPaletteData(forKind kind: WidgetKind) -> WidgetPaletteData? {
        let key = "widget_\(kind.rawValue)"
        let data: Data?
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            data = defaults.data(forKey: key)
        } else {
            data = UserDefaults.standard.data(forKey: key)
        }
        guard let data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let config = try? decoder.decode(WidgetConfigData.self, from: data)
        return config?.palette
    }
}

