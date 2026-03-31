import WidgetKit
import SwiftUI

@main
struct PalettoWidgetBundle: WidgetBundle {
    var body: some Widget {
        PalettoColorWidget()
    }
}

struct PalettoColorWidget: Widget {
    let kind: String = "PalettoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectWidgetPaletteIntent.self, provider: PaletteAppIntentTimelineProvider()) { entry in
            PalettoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Color Palette")
        .description("Display your favorite color palette on the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}



