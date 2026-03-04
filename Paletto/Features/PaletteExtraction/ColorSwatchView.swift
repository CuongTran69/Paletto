import SwiftUI

/// A single color swatch with HEX label and delete action
struct ColorSwatchView: View {
    let color: PaletteColor
    let onDelete: (() -> Void)?

    init(color: PaletteColor, onDelete: (() -> Void)? = nil) {
        self.color = color
        self.onDelete = onDelete
    }

    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(color.color)
                .frame(width: Constants.UI.largeColorSwatchSize, height: Constants.UI.largeColorSwatchSize)
                .shadow(color: color.color.opacity(0.3), radius: Constants.UI.shadowRadiusSmall, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
                .onTapGesture {
                    UIPasteboard.general.string = color.hex
                    showCopied = true
                    if SettingsManager.shared.hapticFeedbackEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }
                .overlay {
                    if showCopied {
                        Text(L10n.copied.localized)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.7))
                            .cornerRadius(4)
                            .transition(.opacity)
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = color.hex
                    } label: {
                        Label(L10n.swatchCopyHex.localized, systemImage: "doc.on.doc")
                    }
                    Button {
                        UIPasteboard.general.string = color.rgbString
                    } label: {
                        Label(L10n.swatchCopyRGB.localized, systemImage: "doc.on.doc")
                    }
                    if let onDelete {
                        Divider()
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(L10n.swatchRemove.localized, systemImage: "trash")
                        }
                    }
                }

            Text(color.hex)
                .font(.caption2.monospaced())
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.swatchA11yLabel.localized(args: ["hex": color.hex]))
        .accessibilityHint(L10n.swatchA11yHint.localized)
    }
}

