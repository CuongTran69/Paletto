import SwiftUI

/// Share palette view — shows URL, QR code, copy & share buttons
struct SharePaletteView: View {
    let palette: ColorPalette
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private let sharingService = PaletteSharingService()

    private var shareURL: URL? {
        sharingService.encode(palette: palette)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.paddingLarge) {
                    palettePreview
                    if let url = shareURL {
                        urlSection(url)
                        qrCodeSection(url)
                        shareButton(url)
                    }
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.shareTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.done.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
        }
    }

    // MARK: - Palette Preview

    private var palettePreview: some View {
        VStack(spacing: 8) {
            Text(palette.name)
                .font(.headline.weight(.semibold))

            HStack(spacing: 4) {
                ForEach(palette.colors) { color in
                    RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                        .fill(color.color)
                        .frame(height: 40)
                        .accessibilityLabel(color.hex)
                }
            }
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
    }

    // MARK: - URL Section

    private func urlSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: L10n.shareLink.localized, icon: "link")

            HStack {
                Text(url.absoluteString)
                    .font(.caption.monospaced())
                    .foregroundColor(SemanticColors.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Spacer()

                Button {
                    UIPasteboard.general.string = url.absoluteString
                    copied = true
                    if SettingsManager.shared.hapticFeedbackEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(copied ? .green : SemanticColors.gradientStart)
                }
                .accessibilityLabel(L10n.shareCopy.localized)
            }
            .padding(Constants.UI.smallPadding)
            .background(SemanticColors.secondaryBackground)
            .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
    }



    // MARK: - QR Code

    private func qrCodeSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.shareQRCode.localized, icon: "qrcode")

            if let qrImage = QRCodeGenerator.generate(from: url.absoluteString, size: 200) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(Constants.UI.padding)
                    .background(Color.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("QR code for sharing palette \(palette.name)")
            }
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Share Button

    private func shareButton(_ url: URL) -> some View {
        Button {
            let activityVC = UIActivityViewController(
                activityItems: [url.absoluteString],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } label: {
            Label(L10n.shareButton.localized, systemImage: "square.and.arrow.up")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SemanticColors.brandGradient)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadiusLarge)
                .shadow(color: SemanticColors.gradientStart.opacity(0.3), radius: Constants.UI.shadowRadiusMedium, y: 4)
        }
        .buttonStyle(.scale)
        .accessibilityLabel(L10n.shareButton.localized)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SemanticColors.brandGradient)
            Text(title)
                .font(.headline.weight(.semibold))
        }
    }
}