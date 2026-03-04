import WidgetKit
import SwiftUI

// MARK: - Shared Data (duplicated for widget target independence)

private let appGroupIdentifier = "group.com.paletto.shared"
private let widgetPaletteKey = "widgetPalette"

/// Lightweight palette data matching main app's WidgetPalette
struct WidgetPaletteData: Codable {
    let id: String
    let name: String
    let hexColors: [String]
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
            hexColors: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (PaletteEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PaletteEntry>) -> Void) {
        let palette = loadWidgetPalette()
        let entry = PaletteEntry(date: .now, palette: palette)
        // Refresh every 30 minutes (in case user changes widget palette)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWidgetPalette() -> WidgetPaletteData? {
        let data: Data?
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            data = defaults.data(forKey: widgetPaletteKey)
        } else {
            // Fallback: try standard UserDefaults (only works if widget and app share same sandbox, unlikely)
            data = UserDefaults.standard.data(forKey: widgetPaletteKey)
            print("[PalettoWidget] ⚠️ App Group not available, tried standard UserDefaults as fallback")
        }
        guard let data else { return nil }
        return try? JSONDecoder().decode(WidgetPaletteData.self, from: data)
    }
}

