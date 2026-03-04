import SwiftUI
import WidgetKit

// MARK: - Widget Entry View

struct PalettoWidgetEntryView: View {
    var entry: PaletteEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let palette = entry.palette {
            switch family {
            case .systemSmall:
                smallWidget(palette)
            case .systemMedium:
                mediumWidget(palette)
            default:
                smallWidget(palette)
            }
        } else {
            emptyState
        }
    }

    // MARK: - Small Widget

    private func smallWidget(_ palette: WidgetPaletteData) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(palette.hexColors.prefix(5), id: \.self) { hex in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorFromHex(hex))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)

            Text(palette.name)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .widgetURL(URL(string: "paletto://palette/\(palette.id)"))
    }

    // MARK: - Medium Widget

    private func mediumWidget(_ palette: WidgetPaletteData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(palette.name)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(1)

            HStack(spacing: 6) {
                ForEach(palette.hexColors.prefix(5), id: \.self) { hex in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorFromHex(hex))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)

                        Text(hex.replacingOccurrences(of: "#", with: ""))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        }
        .padding(12)
        .widgetURL(URL(string: "paletto://palette/\(palette.id)"))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "paintpalette")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Set a palette\nin Paletto")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

