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
        StaticConfiguration(kind: kind, provider: PaletteTimelineProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PalettoWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PalettoWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Color Palette")
        .description("Display your favorite color palette on the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

