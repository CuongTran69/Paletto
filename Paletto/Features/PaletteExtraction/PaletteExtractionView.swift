import SwiftUI
import PhotosUI
import Combine

/// Main extraction screen: pick photo → extract palette → tap-to-pick
struct PaletteExtractionView: View {
    @StateObject private var viewModel = PaletteExtractionViewModel()
    @State private var showSaveDialog = false
    @State private var paletteName = ""
    @State private var savedPalette: ColorPalette?
    @State private var navigateToDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.padding) {
                    imageSection
                    if !viewModel.extractedColors.isEmpty {
                        paletteStrip
                        analyzeButton
                        saveButton
                    }
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.extractionTitle.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showPhotoPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                    .accessibilityLabel(L10n.extractionChoosePhoto.localized)
                }
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView { image in
                    viewModel.onImageSelected(image)
                }
            }
            .alert(L10n.extractionSaveTitle.localized, isPresented: $showSaveDialog) {
                TextField(L10n.extractionSavePlaceholder.localized, text: $paletteName)
                Button(L10n.save.localized) { performSave() }
                Button(L10n.cancel.localized, role: .cancel) {}
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let palette = savedPalette {
                    PaletteDetailView(palette: palette)
                }
            }
            .sheet(isPresented: $viewModel.showAnalysis) {
                if let result = viewModel.analysisResult {
                    ImageAnalysisView(result: result)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imageSection: some View {
        if let image = viewModel.selectedImage {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(Constants.UI.cornerRadiusLarge)
                    .overlay(
                        MagnifierOverlay(
                            image: image,
                            position: $viewModel.magnifierPosition,
                            pickedColor: $viewModel.magnifierColor,
                            onPick: { point in
                                viewModel.pickColor(at: point)
                            },
                            onRelease: {
                                viewModel.addPickedColor()
                            }
                        )
                    )

                if viewModel.isExtracting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Constants.UI.cornerRadius)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.extractionImageA11y.localized)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(SemanticColors.gradientStart.opacity(0.1))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(SemanticColors.gradientEnd.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "paintpalette")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(SemanticColors.brandGradient)
            }
            Text(L10n.extractionEmptyTitle.localized)
                .font(.title3.weight(.semibold))
            Button {
                viewModel.showPhotoPicker = true
            } label: {
                Label(L10n.extractionEmptyButton.localized, systemImage: "photo")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, Constants.UI.paddingXL)
                    .padding(.vertical, 14)
                    .background(SemanticColors.brandGradient)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadiusLarge)
                    .shadow(color: SemanticColors.gradientStart.opacity(0.3), radius: Constants.UI.shadowRadiusMedium, y: 4)
            }
            .buttonStyle(.scale)
            .accessibilityLabel(L10n.extractionEmptyButtonA11y.localized)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var paletteStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.extractionPaletteTitle.localized)
                    .font(.headline.weight(.semibold))
                Spacer()
                Text(L10n.extractionPaletteCount.localized(args: ["count": "\(viewModel.extractedColors.count)"]))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.extractedColors.enumerated()), id: \.element.id) { index, color in
                        ColorSwatchView(color: color) {
                            viewModel.removeColor(at: index)
                        }
                    }
                }
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

    private var analyzeButton: some View {
        Button {
            viewModel.analyzeImage()
        } label: {
            Label(L10n.analysisAnalyze.localized, systemImage: "chart.bar.xaxis")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .foregroundStyle(SemanticColors.brandGradient)
                .cornerRadius(Constants.UI.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(.scale)
        .accessibilityLabel(L10n.analysisAnalyze.localized)
    }

    private var saveButton: some View {
        Button {
            showSaveDialog = true
        } label: {
            Label(L10n.extractionSavePalette.localized, systemImage: "square.and.arrow.down")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SemanticColors.brandGradient)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadiusLarge)
                .shadow(color: SemanticColors.gradientStart.opacity(0.3), radius: Constants.UI.shadowRadiusMedium, y: 4)
        }
        .buttonStyle(.scale)
        .accessibilityLabel(L10n.extractionSavePaletteA11y.localized)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(Constants.UI.smallCornerRadius)
    }

    // MARK: - Actions

    private func performSave() {
        viewModel.savePalette(name: paletteName)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { palette in
                    savedPalette = palette
                    navigateToDetail = true
                    paletteName = ""
                }
            )
            .store(in: &saveCancellables)
    }

    @State private var saveCancellables = Set<AnyCancellable>()
}

