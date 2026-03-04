import SwiftUI

/// Row showing a single color with its details and role picker (glass card style)
struct ColorDetailRow: View {
    let color: PaletteColor
    let onRoleChanged: (ColorRole) -> Void
    let onCopyHex: () -> Void
    var onGenerateHarmony: (() -> Void)?

    @State private var showCopied = false

    var body: some View {
        HStack(spacing: 14) {
            // Color swatch — larger with colored shadow
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(color.color)
                .frame(width: Constants.UI.largeColorSwatchSize, height: Constants.UI.largeColorSwatchSize)
                .shadow(color: color.color.opacity(0.35), radius: Constants.UI.shadowRadiusMedium, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
                .contextMenu {
                    if let onGenerateHarmony {
                        Button {
                            onGenerateHarmony()
                        } label: {
                            Label(L10n.harmonyGenerate.localized, systemImage: "paintpalette.fill")
                        }
                    }
                }

            // Color info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(color.hex)
                        .font(.body.monospaced().weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if showCopied {
                        Text(L10n.copied.localized)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(SemanticColors.success)
                            .transition(.opacity)
                    }
                }
                Text("RGB: \(color.rgbString)")
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("HSB: \(color.hsbString)")
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .onTapGesture {
                onCopyHex()
                withAnimation(.spring(response: Constants.UI.springResponse, dampingFraction: Constants.UI.springDamping)) {
                    showCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCopied = false }
                }
            }

            Spacer()

            // Role picker — gradient tag
            Menu {
                ForEach(ColorRole.allCases) { role in
                    Button {
                        onRoleChanged(role)
                    } label: {
                        Label(role.displayName, systemImage: role.iconName)
                    }
                }
            } label: {
                if let role = color.role {
                    Text(role.displayName)
                        .font(.caption.weight(.bold))
                        .foregroundColor(color.relativeLuminance > 0.5 ? .black : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.color.opacity(0.3))
                        .cornerRadius(Constants.UI.smallCornerRadius)
                } else {
                    Image(systemName: "tag")
                        .font(.body)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .accessibilityLabel(L10n.colorDetailRoleA11y.localized(args: ["role": color.role?.displayName ?? L10n.none.localized]))
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
        .shadow(color: color.color.opacity(0.1), radius: Constants.UI.shadowRadiusSmall, y: 2)
        .accessibilityElement(children: .combine)
    }
}

