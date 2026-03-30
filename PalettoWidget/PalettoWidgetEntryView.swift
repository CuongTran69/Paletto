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
            case .systemLarge:
                largeWidget(palette)
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

    // MARK: - Large Widget

    private func largeWidget(_ palette: WidgetPaletteData) -> some View {
        VStack(spacing: 12) {
            Text(palette.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    if index < palette.hexColors.count {
                        let hex = palette.hexColors[index]
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorFromHex(hex))
                                .frame(height: 44)
                            Text(hex.replacingOccurrences(of: "#", with: ""))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if let role = palette.colorRoles[safe: index], !role.isEmpty {
                                Text(role)
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .accessibilityLabel("Color \(hex), \(palette.colorRoles[safe: index] ?? "no role") role")
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                            .frame(height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                            )
                    }
                }
            }

            Text("Paletto · Tap to open")
                .font(.caption2)
                .foregroundColor(.secondary)
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
            // Widget extension cannot share the app's JSON localization bundle.
            // Uses String(localized:) so this can be localized via .strings files.
            Text(String(localized: "widget.empty.message", defaultValue: "Set a palette\nin Paletto"))
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

