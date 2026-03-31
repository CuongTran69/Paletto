import SwiftUI

/// Library screen showing all saved palettes with folder and tag filtering
struct PaletteListView: View {
    @StateObject private var viewModel = PaletteListViewModel()
    @State private var showComparison = false
    @Binding var deepLinkPaletteID: UUID?
    @State private var deepLinkPalette: ColorPalette?
    @State private var navigateToDeepLink = false

    // Folder creation/rename sheet state
    @State private var showCreateFolderSheet = false
    @State private var newFolderName = ""
    @State private var showRenameFolderSheet = false
    @State private var renameFolderTarget: Folder?
    @State private var renameFolderText = ""
    @State private var showDeleteFolderConfirmation = false
    @State private var folderToDelete: Folder?
    @State private var createFolderError: String?
    @State private var renameFolderError: String?

    // Palette count per tag
    private var tagPaletteCounts: [String: Int] {
        var counts = [String: Int]()
        for palette in viewModel.palettes {
            for tag in palette.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else if viewModel.selectedFolder != nil {
                    folderDetailView
                } else if viewModel.filteredPalettes.isEmpty {
                    emptyState
                } else {
                    paletteList
                }
            }
            .navigationTitle(L10n.libraryTitle.localized)
            .searchable(text: $viewModel.searchText, prompt: Text(L10n.librarySearchPrompt.localized))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showComparison = true
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundStyle(SemanticColors.brandGradient)
                        }
                        .accessibilityLabel(L10n.comparisonTitle.localized)
                    }
                }
            }
            .sheet(isPresented: $showComparison) {
                PaletteComparisonView()
            }
            .sheet(isPresented: $showCreateFolderSheet) {
                createFolderSheet
            }
            .sheet(isPresented: $showRenameFolderSheet) {
                renameFolderSheet
            }
            .alert(
                L10n.libraryFolderDeleteConfirm.localized(args: ["name": folderToDelete?.name ?? ""]),
                isPresented: $showDeleteFolderConfirmation
            ) {
                Button(L10n.cancel.localized, role: .cancel) {
                    folderToDelete = nil
                }
                Button(L10n.delete.localized, role: .destructive) {
                    if let folder = folderToDelete {
                        viewModel.deleteFolder(folder)
                    }
                    folderToDelete = nil
                }
            }
            .navigationDestination(isPresented: $navigateToDeepLink) {
                if let palette = deepLinkPalette {
                    PaletteDetailView(palette: palette)
                }
            }
            .onAppear {
                viewModel.loadPalettes()
            }
            .onChangeCompat(of: viewModel.isLoading) { isLoading in
                if !isLoading {
                    handleDeepLinkIfNeeded()
                }
            }
            .onChangeCompat(of: deepLinkPaletteID) { _ in
                if !viewModel.isLoading {
                    handleDeepLinkIfNeeded()
                }
            }
        }
    }

    // MARK: - Deep Link

    private func handleDeepLinkIfNeeded() {
        guard let id = deepLinkPaletteID else { return }
        deepLinkPaletteID = nil
        if let palette = viewModel.palettes.first(where: { $0.id == id }) {
            deepLinkPalette = palette
            navigateToDeepLink = true
        }
    }

    // MARK: - Folder Detail View

    private var folderDetailView: some View {
        VStack(spacing: 0) {
            // Back to Library breadcrumb
            Button {
                viewModel.selectedFolder = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.libraryFolderBack.localized)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(SemanticColors.brandGradient)
                .padding(.horizontal, Constants.UI.padding)
                .padding(.vertical, Constants.UI.smallPadding)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.filteredPalettes.isEmpty {
                        emptyFolderState
                    } else {
                        paletteListContent
                    }
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
            }
        }
    }

    private var emptyFolderState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(SemanticColors.brandGradient)
            Text(L10n.libraryFolderEmpty.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Palette List

    private var paletteList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Tag filter bar (always visible when not inside a folder)
                if !viewModel.allTags.isEmpty {
                    TagFilterBar(
                        selectedTag: $viewModel.selectedTag,
                        allTags: viewModel.allTags,
                        paletteCounts: tagPaletteCounts,
                        onNewTag: { tag in
                            // Create palette with tag — just show tag selected; actual creation happens in detail
                            viewModel.selectedTag = tag
                        }
                    )
                }

                // Folder section
                if !viewModel.folders.isEmpty {
                    FolderSection(
                        folders: viewModel.folders,
                        palettes: viewModel.palettes,
                        selectedFolder: $viewModel.selectedFolder,
                        onCreateFolder: {
                            newFolderName = ""
                            showCreateFolderSheet = true
                        },
                        onRenameFolder: { folder in
                            renameFolderTarget = folder
                            renameFolderText = folder.name
                            showRenameFolderSheet = true
                        },
                        onDeleteFolder: { folder in
                            folderToDelete = folder
                            showDeleteFolderConfirmation = true
                        }
                    )
                }

                // "All Palettes" header when not filtering by folder
                if viewModel.selectedFolder == nil {
                    Text("All Palettes")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(SemanticColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                paletteListContent
            }
            .padding(.horizontal, 0)
            .padding(.top, Constants.UI.smallPadding)
            .padding(.bottom, Constants.UI.paddingXL)
        }
    }

    private var paletteListContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredPalettes) { palette in
                NavigationLink {
                    PaletteDetailView(palette: palette)
                } label: {
                    PaletteRowView(palette: palette)
                }
                .buttonStyle(.scale)
                .contextMenu {
                    Button(role: .destructive) {
                        if let idx = viewModel.filteredPalettes.firstIndex(where: { $0.id == palette.id }) {
                            viewModel.deletePalette(at: IndexSet(integer: idx))
                        }
                    } label: {
                        Label(L10n.swatchRemove.localized, systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, Constants.UI.padding)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(SemanticColors.destructive)
                .accessibilityHidden(true)
            Text(L10n.libraryErrorTitle.localized)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                viewModel.errorMessage = nil
                viewModel.loadPalettes()
            } label: {
                Label(L10n.libraryErrorRetry.localized, systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, Constants.UI.paddingXL)
                    .padding(.vertical, 12)
                    .background(SemanticColors.brandGradient)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadiusLarge)
            }
        }
        .padding(Constants.UI.paddingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(SemanticColors.gradientStart.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(SemanticColors.gradientEnd.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "books.vertical")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColors.brandGradient)
            }

            if viewModel.searchText.isEmpty {
                Text(L10n.libraryEmptyTitle.localized)
                    .font(.title3.weight(.semibold))
                Text(L10n.libraryEmptySubtitle.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(L10n.librarySearchNoResults.localized(args: ["query": viewModel.searchText]))
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(Constants.UI.paddingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Folder Sheets

    private var createFolderSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField(L10n.libraryFolderCreatePlaceholder.localized, text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChangeCompat(of: newFolderName) { _ in
                        createFolderError = nil
                    }

                if let error = createFolderError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(SemanticColors.destructive)
                }

                if viewModel.folders.count >= Constants.Folder.maxCount {
                    Text(L10n.libraryFolderErrorMaxCount.localized)
                        .font(.caption)
                        .foregroundColor(SemanticColors.destructive)
                }
            }
            .navigationTitle(L10n.libraryFolderCreateTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel.localized) {
                        showCreateFolderSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save.localized) {
                        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count > Constants.Folder.maxNameLength {
                            createFolderError = L10n.libraryFolderErrorMaxLength.localized
                            return
                        }
                        viewModel.createFolder(name: trimmed)
                        showCreateFolderSheet = false
                    }
                    .disabled(isCreateFolderSaveDisabled)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var isCreateFolderSaveDisabled: Bool {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || viewModel.folders.count >= Constants.Folder.maxCount
    }

    private var renameFolderSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField(L10n.libraryFolderCreatePlaceholder.localized, text: $renameFolderText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChangeCompat(of: renameFolderText) { _ in
                        renameFolderError = nil
                    }

                if let error = renameFolderError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(SemanticColors.destructive)
                }
            }
            .navigationTitle(L10n.libraryFolderRename.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel.localized) {
                        showRenameFolderSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save.localized) {
                        let trimmed = renameFolderText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count > Constants.Folder.maxNameLength {
                            renameFolderError = L10n.libraryFolderErrorMaxLength.localized
                            return
                        }
                        if viewModel.folders.contains(where: {
                            $0.id != renameFolderTarget?.id && $0.name == trimmed
                        }) {
                            renameFolderError = L10n.libraryFolderErrorDuplicate.localized
                            return
                        }
                        if let folder = renameFolderTarget {
                            viewModel.renameFolder(folder, to: trimmed)
                        }
                        showRenameFolderSheet = false
                    }
                    .disabled(isRenameFolderSaveDisabled)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var isRenameFolderSaveDisabled: Bool {
        let trimmed = renameFolderText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
    }
}

/// Row view for a single palette in the list — glass card style with optional tag chips
struct PaletteRowView: View {
    let palette: ColorPalette

    private var dominantColor: Color {
        palette.colors.first?.color ?? SemanticColors.gradientStart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Color strip
            HStack(spacing: 3) {
                ForEach(palette.colors) { color in
                    RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                        .fill(color.color)
                        .frame(height: Constants.UI.swatchSizeMedium)
                        .shadow(color: color.color.opacity(0.3), radius: 4, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(palette.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    Spacer()
                    Text(palette.formattedDate)
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
                }

                // Tag chips (shown when palette has tags)
                if !palette.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(palette.tags.prefix(5), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(SemanticColors.gradientStart)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(SemanticColors.gradientStart.opacity(0.1))
                                    .cornerRadius(6)
                                    .accessibilityLabel("Tag: \(tag)")
                            }
                            if palette.tags.count > 5 {
                                Text("+\(palette.tags.count - 5)")
                                    .font(.caption2)
                                    .foregroundColor(SemanticColors.secondaryText)
                                    .accessibilityLabel("\(palette.tags.count - 5) more tags")
                            }
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
        .shadow(color: dominantColor.opacity(0.12), radius: Constants.UI.shadowRadiusMedium, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.libraryRowA11y.localized(args: [
            "name": palette.name,
            "count": "\(palette.colorCount)",
            "date": palette.formattedDate
        ]))
    }
}
