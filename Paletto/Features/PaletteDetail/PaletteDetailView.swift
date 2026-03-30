import SwiftUI
import WidgetKit

/// Detail view for a saved palette — roles, contrast, preview (glass card style)
struct PaletteDetailView: View {
    @StateObject private var viewModel: PaletteDetailViewModel
    @State private var editingName = false
    @State private var showContrastInfo = false
    @State private var selectedPreviewStyle: PreviewStyle = .appCard
    @State private var showBlindness = false
    @State private var selectedWidgetSize: WidgetKind?
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.undoManager) private var undoManager: UndoManager?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(palette: ColorPalette) {
        _viewModel = StateObject(wrappedValue: PaletteDetailViewModel(palette: palette))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.paddingLarge) {
                nameSection
                tagEditorSection
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
            // Undo/Redo on leading side
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    Button {
                        triggerHapticIfEnabled()
                        undoManager?.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .disabled(undoManager?.canUndo != true)
                    .accessibilityLabel(undoManager?.undoActionName.map { "Undo \($0)" } ?? "Undo")

                    Button {
                        triggerHapticIfEnabled()
                        undoManager?.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .disabled(undoManager?.canRedo != true)
                    .accessibilityLabel(undoManager?.redoActionName.map { "Redo \($0)" } ?? "Redo")
                }
            }

            // Trailing toolbar
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

                    Menu {
                        Menu {
                            Button {
                                selectedWidgetSize = .small
                                viewModel.setAsWidget(forKind: .small)
                            } label: {
                                Label(L10n.widgetSizeSmall.localized, systemImage: "rectangle")
                            }

                            Button {
                                selectedWidgetSize = .medium
                                viewModel.setAsWidget(forKind: .medium)
                            } label: {
                                Label(L10n.widgetSizeMedium.localized, systemImage: "rectangle.split.2x1")
                            }

                            Button {
                                selectedWidgetSize = .large
                                viewModel.setAsWidget(forKind: .large)
                            } label: {
                                Label(L10n.widgetSizeLarge.localized, systemImage: "rectangle.split.3x1")
                            }
                        } label: {
                            Label(L10n.widgetSetAs.localized, systemImage: "rectangle.on.rectangle")
                        }

                        Divider()

                        Button {
                            viewModel.showExport = true
                        } label: {
                            Label(L10n.detailExport.localized, systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.detailExport.localized)
                }
            }
        }
        .onAppear {
            viewModel.undoManager = undoManager
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
        .alert(widgetConfirmationTitle, isPresented: $viewModel.showWidgetConfirmation) {
            Button(L10n.done.localized, role: .cancel) {}
        }
    }

    private func triggerHapticIfEnabled() {
        if let settingsManager = SettingsManager.shared as? SettingsManager,
           settingsManager.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private var widgetConfirmationTitle: String {
        guard let size = selectedWidgetSize else {
            return L10n.widgetSetConfirm.localized
        }
        let sizeKey: String
        switch size {
        case .small: sizeKey = L10n.widgetSizeSmall.localized
        case .medium: sizeKey = L10n.widgetSizeMedium.localized
        case .large: sizeKey = L10n.widgetSizeLarge.localized
        }
        return L10n.widgetSizeConfirm.localized(args: ["size": sizeKey])
    }

    // MARK: - Sections

    @ViewBuilder
    private var nameSection: some View {
        if editingName {
            HStack(spacing: 10) {
                TextField(L10n.detailNamePlaceholder.localized, text: $viewModel.palette.name)
                    .font(.title2.weight(.semibold))
                    .focused($isNameFieldFocused)
                Button {
                    isNameFieldFocused = false
                    editingName = false
                    viewModel.updateName(viewModel.palette.name)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
                .accessibilityLabel(L10n.detailNameConfirmA11y.localized)
            }
            .padding(Constants.UI.padding)
            .background(.ultraThinMaterial)
            .cornerRadius(Constants.UI.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                    .strokeBorder(SemanticColors.gradientStart.opacity(0.4), lineWidth: 1.5)
            )
            .onSubmit {
                isNameFieldFocused = false
                editingName = false
                viewModel.updateName(viewModel.palette.name)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNameFieldFocused = true
                }
            }
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

    private var tagEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tags")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(SemanticColors.primaryText)

                Spacer()

                Button {
                    viewModel.showTagEditor.toggle()
                } label: {
                    Image(systemName: viewModel.showTagEditor ? "checkmark.circle.fill" : "plus.circle")
                        .font(.body)
                        .foregroundStyle(SemanticColors.brandGradient)
                }
                .accessibilityLabel(viewModel.showTagEditor ? "Done editing tags" : "Add tags")
            }

            if viewModel.showTagEditor || !viewModel.palette.tags.isEmpty {
                tagChipsView
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

    private var tagChipsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tag chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.palette.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SemanticColors.gradientStart)

                            Button {
                                viewModel.removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(SemanticColors.secondaryText)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SemanticColors.gradientStart.opacity(0.1))
                        .cornerRadius(16)
                    }

                    // "+ Add Tag" button
                    if viewModel.showTagEditor {
                        Button {
                            // Show inline text field
                            viewModel.showTagEditor = false
                            // Toggle the tag editor to show inline field
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                Text(L10n.libraryTagAdd.localized)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(SemanticColors.gradientStart)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SemanticColors.gradientStart.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                }
            }

            // Inline add tag field (shown when tag editor is active)
            if viewModel.showTagEditor {
                HStack(spacing: 8) {
                    TextField(L10n.libraryTagPlaceholder.localized, text: $viewModel.newTagText)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onSubmit {
                            if viewModel.addTag(viewModel.newTagText) {
                                viewModel.newTagText = ""
                            }
                        }
                        .onChangeCompat(of: viewModel.newTagText) { _ in
                            viewModel.clearTagError()
                        }

                    Button {
                        if viewModel.addTag(viewModel.newTagText) {
                            viewModel.newTagText = ""
                        }
                    } label: {
                        Text(L10n.libraryTagAdd.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(SemanticColors.gradientStart)
                            .cornerRadius(8)
                    }

                    Button {
                        viewModel.newTagText = ""
                        viewModel.clearTagError()
                        viewModel.showTagEditor = false
                    } label: {
                        Text(L10n.cancel.localized)
                            .font(.subheadline)
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                }

                if let error = viewModel.tagError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(SemanticColors.destructive)
                }
            }
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
                        .accessibilityHidden(true)

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
                .animation(reduceMotion ? .none : .easeInOut(duration: Constants.UI.animationDuration), value: selectedPreviewStyle)
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
