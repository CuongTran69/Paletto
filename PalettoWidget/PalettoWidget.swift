import WidgetKit
import SwiftUI

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

