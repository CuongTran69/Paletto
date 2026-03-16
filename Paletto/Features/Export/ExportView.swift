import SwiftUI

/// Export screen with format selection and share (glass style)
struct ExportView: View {
    let palette: ColorPalette
    @State private var selectedFormat: ExportFormat = .image
    @State private var exportedContent: String = ""
    @State private var exportedImage: UIImage?
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private let exportService = ExportService()

    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.UI.padding) {
                // Format picker
                Picker(L10n.exportFormatLabel.localized, selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Label(format.displayName, systemImage: format.iconName)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedFormat) { _ in generateExport() }

                // Preview — glass card
                ScrollView {
                    if selectedFormat == .image, let image = exportedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(Constants.UI.cornerRadiusLarge)
                            .shadow(color: SemanticColors.glassShadow, radius: Constants.UI.shadowRadiusMedium, y: 3)
                            .accessibilityLabel("Exported palette image for \(palette.name)")
                    } else {
                        Text(exportedContent)
                            .font(.system(.caption, design: .monospaced))
                            .padding(Constants.UI.padding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                            .cornerRadius(Constants.UI.cornerRadiusLarge)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                                    .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                            )
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label(L10n.exportCopy.localized, systemImage: "doc.on.doc")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .cornerRadius(Constants.UI.cornerRadiusLarge)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                                    .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.scale)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label(L10n.exportShare.localized, systemImage: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SemanticColors.brandGradient)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadiusLarge)
                            .shadow(color: SemanticColors.gradientStart.opacity(0.3), radius: 4, y: 2)
                    }
                    .buttonStyle(.scale)
                }
            }
            .padding(Constants.UI.padding)
            .navigationTitle(L10n.exportTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.exportDone.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems())
            }
            .onAppear { generateExport() }
        }
    }

    // MARK: - Actions

    private func generateExport() {
        switch selectedFormat {
        case .image:
            exportedImage = exportService.exportAsImage(palette: palette)
            exportedContent = ""
        case .swiftUI:
            exportedContent = exportService.exportAsSwiftUI(palette: palette)
            exportedImage = nil
        case .css:
            exportedContent = exportService.exportAsCSS(palette: palette)
            exportedImage = nil
        case .hexList:
            exportedContent = exportService.exportAsHexList(palette: palette)
            exportedImage = nil
        case .jsonTokens:
            exportedContent = exportService.exportAsJSONTokens(palette: palette)
            exportedImage = nil
        }
    }

    private func copyToClipboard() {
        if selectedFormat == .image, let image = exportedImage {
            UIPasteboard.general.image = image
        } else {
            UIPasteboard.general.string = exportedContent
        }
        if SettingsManager.shared.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func shareItems() -> [Any] {
        if selectedFormat == .image, let image = exportedImage {
            return [image]
        }
        return [exportedContent]
    }
}

/// UIActivityViewController wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

