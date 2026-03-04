import SwiftUI

/// Detail view for a saved palette — roles, contrast, preview (glass card style)
struct PaletteDetailView: View {
    @StateObject private var viewModel: PaletteDetailViewModel
    @State private var editingName = false
    @State private var showContrastInfo = false
    @State private var selectedPreviewStyle: PreviewStyle = .appCard
    @State private var showBlindness = false

    init(palette: ColorPalette) {
        _viewModel = StateObject(wrappedValue: PaletteDetailViewModel(palette: palette))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.paddingLarge) {
                nameSection
                colorsSection
                contrastMatrixSection
                previewSection
            }
            .padding(.horizontal, Constants.UI.padding)
            .padding(.top, Constants.UI.smallPadding)
            .padding(.bottom, Constants.UI.paddingXL)
        }
        .background(SemanticColors.appBackground)
        .navigationTitle(L10n.detailTitle.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.autoAssignRoles()
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.detailAutoAssign.localized)

                    Button {
                        showBlindness = true
                    } label: {
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.blindnessSimulate.localized)

                    Button {
                        viewModel.showShare = true
                    } label: {
                        Image(systemName: "link")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.shareTitle.localized)

                    Button {
                        viewModel.showExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.detailExport.localized)
                }
            }
        }
        .sheet(isPresented: $viewModel.showExport) {
            ExportView(palette: viewModel.palette)
        }
        .sheet(isPresented: $viewModel.showHarmony) {
            if let sourceColor = viewModel.harmonySourceColor {
                ColorHarmonyView(sourceColor: sourceColor)
            }
        }
        .sheet(isPresented: $showBlindness) {
            ColorBlindnessView(palette: viewModel.palette)
        }
        .sheet(isPresented: $viewModel.showShare) {
            SharePaletteView(palette: viewModel.palette)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var nameSection: some View {
        if editingName {
            HStack(spacing: 10) {
                TextField(L10n.detailNamePlaceholder.localized, text: $viewModel.palette.name)
                    .font(.title2.weight(.semibold))
                Button {
                    editingName = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .padding(Constants.UI.padding)
            .background(.ultraThinMaterial)
            .cornerRadius(Constants.UI.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                    .strokeBorder(SemanticColors.gradientStart.opacity(0.4), lineWidth: 1.5)
            )
            .onSubmit { editingName = false }
        } else {
            HStack {
                Text(viewModel.palette.name)
                    .font(.title2.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer()
                Button {
                    editingName = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
                .accessibilityLabel(L10n.detailNameEditA11y.localized)
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

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.detailSectionColors.localized, icon: "paintpalette.fill")

            if viewModel.palette.colors.isEmpty {
                Text(L10n.detailEmptyColors.localized)
                    .font(.subheadline)
                    .foregroundColor(SemanticColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.UI.paddingLarge)
            } else {
                ForEach(Array(viewModel.palette.colors.enumerated()), id: \.element.id) { index, color in
                    ColorDetailRow(
                        color: color,
                        onRoleChanged: { role in
                            viewModel.updateRole(for: color.id, to: role)
                        },
                        onCopyHex: {
                            viewModel.copyHex(color.hex)
                        },
                        onGenerateHarmony: {
                            viewModel.openHarmony(for: color)
                        }
                    )
                }
            }
        }
    }

    private var contrastMatrixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: L10n.detailSectionContrast.localized, icon: "circle.lefthalf.filled")
                Spacer()
                Button {
                    showContrastInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
                .accessibilityLabel(L10n.detailContrastInfoButton.localized)
            }

            ContrastMatrixView(
                colors: viewModel.palette.colors,
                matrix: viewModel.contrastMatrix,
                onFixSuggested: { fg, bg in
                    if let fix = viewModel.suggestFix(foregroundIndex: fg, backgroundIndex: bg) {
                        viewModel.applyFix(fix, at: fg)
                    }
                }
            )
        }
        .sheet(isPresented: $showContrastInfo) {
            contrastInfoSheet
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.detailSectionPreview.localized, icon: "eye.fill")

            // Role assignment hint banner
            if !viewModel.palette.allRolesAssigned {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)

                    Text(L10n.previewRoleHint.localized)
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Button {
                        viewModel.autoAssignRoles()
                    } label: {
                        Text(L10n.previewAutoAssign.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [SemanticColors.gradientStart, SemanticColors.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Constants.UI.smallCornerRadius)
                    }
                    .accessibilityLabel(L10n.previewAutoAssign.localized)
                }
                .padding(Constants.UI.padding)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(Constants.UI.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
                )
            }

            // Style picker
            Picker("", selection: $selectedPreviewStyle) {
                ForEach(PreviewStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)

            PreviewCardView(palette: viewModel.palette, style: selectedPreviewStyle)
                .animation(.easeInOut(duration: Constants.UI.animationDuration), value: selectedPreviewStyle)
        }
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

    private var contrastInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.UI.padding) {
                    Text(L10n.detailContrastInfoBody.localized)
                        .font(.body)
                        .foregroundColor(SemanticColors.primaryText)
                }
                .padding(Constants.UI.paddingLarge)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.detailContrastInfoTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done.localized) {
                        showContrastInfo = false
                    }
                }
            }
        }
    }
}

