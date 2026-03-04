import SwiftUI
import Combine

/// Color harmony generator view — shows harmonious colors from a source color
struct ColorHarmonyView: View {
    @StateObject private var viewModel: ColorHarmonyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveAlert = false
    @State private var paletteName = ""
    @State private var showCopiedIndex: Int?
    @State private var isSaving = false

    init(sourceColor: PaletteColor) {
        _viewModel = StateObject(wrappedValue: ColorHarmonyViewModel(sourceColor: sourceColor))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.paddingLarge) {
                    sourceColorSection
                    harmonyTypePicker
                    harmonyDescription
                    harmonyColorsGrid
                    saveButton
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.harmonyTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.done.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .alert(L10n.harmonySaveTitle.localized, isPresented: $showSaveAlert) {
                TextField(L10n.harmonySavePlaceholder.localized, text: $paletteName)
                Button(L10n.save.localized) { savePalette() }
                Button(L10n.cancel.localized, role: .cancel) { }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.harmonyA11y.localized)
        }
    }


    // MARK: - Source Color

    private var sourceColorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.harmonySourceColor.localized)
                .font(.headline.weight(.semibold))

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(viewModel.sourceColor.color)
                    .frame(width: Constants.UI.largeColorSwatchSize, height: Constants.UI.largeColorSwatchSize)
                    .shadow(color: viewModel.sourceColor.color.opacity(0.35), radius: Constants.UI.shadowRadiusMedium, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.sourceColor.hex)
                        .font(.body.monospaced().weight(.semibold))
                    Text("HSB: \(viewModel.sourceColor.hsbString)")
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
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
    }

    // MARK: - Harmony Type Picker

    private var harmonyTypePicker: some View {
        Picker("", selection: $viewModel.selectedType) {
            ForEach(HarmonyType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedType) { newType in
            viewModel.selectType(newType)
        }
    }

    private var harmonyDescription: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.selectedType.iconName)
                .font(.caption)
                .foregroundStyle(SemanticColors.brandGradient)
            Text(viewModel.selectedType.description)
                .font(.caption)
                .foregroundColor(SemanticColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Harmony Colors Grid

    private var harmonyColorsGrid: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.harmonyColors.enumerated()), id: \.element.id) { index, color in
                harmonyColorRow(color: color, index: index)
            }
        }
    }

    private func harmonyColorRow(color: PaletteColor, index: Int) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(color.color)
                .frame(width: Constants.UI.largeColorSwatchSize, height: Constants.UI.largeColorSwatchSize)
                .shadow(color: color.color.opacity(0.35), radius: Constants.UI.shadowRadiusMedium, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(color.hex)
                        .font(.body.monospaced().weight(.semibold))
                    if showCopiedIndex == index {
                        Text(L10n.copied.localized)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(SemanticColors.success)
                            .transition(.opacity)
                    }
                }
                Text("RGB: \(color.rgbString)")
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
            }

            Spacer()

            if index == 0 {
                Text(L10n.harmonySourceColor.localized)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(SemanticColors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SemanticColors.secondaryBackground)
                    .cornerRadius(Constants.UI.smallCornerRadius)
            }
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
        .shadow(color: color.color.opacity(0.1), radius: Constants.UI.shadowRadiusSmall, y: 2)
        .onTapGesture {
            viewModel.copyHex(color.hex)
            withAnimation(.spring(response: Constants.UI.springResponse, dampingFraction: Constants.UI.springDamping)) {
                showCopiedIndex = index
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showCopiedIndex = nil }
            }
        }
        .accessibilityLabel(L10n.harmonyColorA11y.localized(args: ["hex": color.hex]))
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            showSaveAlert = true
        } label: {
            Label(L10n.harmonySaveAsPalette.localized, systemImage: "square.and.arrow.down")
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

    // MARK: - Actions

    private func savePalette() {
        isSaving = true
        var cancellable: AnyCancellable?
        cancellable = viewModel.savePalette(name: paletteName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    isSaving = false
                    cancellable?.cancel()
                },
                receiveValue: { _ in
                    if SettingsManager.shared.hapticFeedbackEnabled {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    dismiss()
                }
            )
    }
}