import SwiftUI

/// Collapsible "My Folders" section for the Library screen
struct FolderSection: View {
    let folders: [Folder]
    let palettes: [ColorPalette]
    @Binding var selectedFolder: Folder?
    var onCreateFolder: (() -> Void)?
    var onRenameFolder: ((Folder) -> Void)?
    var onDeleteFolder: ((Folder) -> Void)?

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: Constants.UI.animationDuration)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(L10n.libraryFolderTitle.localized)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(SemanticColors.primaryText)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                .padding(.horizontal, Constants.UI.padding)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(folders) { folder in
                        FolderRowView(
                            folder: folder,
                            paletteCount: paletteCount(for: folder),
                            isSelected: selectedFolder?.id == folder.id,
                            onTap: {
                                selectedFolder = folder
                            },
                            onRename: {
                                onRenameFolder?(folder)
                            },
                            onDelete: {
                                onDeleteFolder?(folder)
                            }
                        )
                    }

                    Button {
                        onCreateFolder?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(SemanticColors.brandGradient)
                            Text(L10n.libraryFolderNew.localized)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SemanticColors.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, Constants.UI.padding)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Constants.UI.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Constants.UI.padding)
            }
        }
    }

    private func paletteCount(for folder: Folder) -> Int {
        palettes.filter { folder.paletteIds.contains($0.id) }.count
    }
}

/// Single folder row with context menu actions
struct FolderRowView: View {
    let folder: Folder
    let paletteCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(SemanticColors.brandGradient)

                Text(folder.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SemanticColors.primaryText)
                    .lineLimit(1)

                Spacer()

                Text("\(paletteCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? .white : SemanticColors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isSelected
                            ? SemanticColors.gradientStart
                            : Color(.systemGray5)
                    )
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Constants.UI.padding)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(
                        colors: [SemanticColors.gradientStart.opacity(0.15), SemanticColors.gradientEnd.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .strokeBorder(
                        isSelected ? SemanticColors.gradientStart.opacity(0.35) : SemanticColors.glassBorder,
                        lineWidth: 0.75
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label(L10n.libraryFolderRename.localized, systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.libraryFolderDelete.localized, systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(folder.name), \(paletteCount) palettes")
    }
}
