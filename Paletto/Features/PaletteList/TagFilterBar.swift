import SwiftUI

/// Horizontal scrolling tag filter bar with "All", tag chips, and "+ New Tag" button
struct TagFilterBar: View {
    @Binding var selectedTag: String?
    let allTags: [String]
    let paletteCounts: [String: Int]
    var onNewTag: ((String) -> Void)?

    @State private var showNewTagField = false
    @State private var newTagText = ""
    @State private var newTagError: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                tagChip(
                    label: L10n.libraryTagAll.localized,
                    isSelected: selectedTag == nil,
                    count: nil
                ) {
                    selectedTag = nil
                }

                // Tag chips
                ForEach(allTags, id: \.self) { tag in
                    tagChip(
                        label: tag,
                        isSelected: selectedTag == tag,
                        count: paletteCounts[tag]
                    ) {
                        selectedTag = selectedTag == tag ? nil : tag
                    }
                }

                // "+ New Tag" chip or inline text field
                if showNewTagField {
                    newTagInlineField
                } else {
                    addTagButton
                }
            }
            .padding(.horizontal, Constants.UI.padding)
        }
    }

    private func tagChip(
        label: String,
        isSelected: Bool,
        count: Int?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : SemanticColors.primaryText)
                if let count = count, count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : SemanticColors.secondaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(
                        colors: [SemanticColors.gradientStart, SemanticColors.gradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    : AnyShapeStyle(Color.clear)
            )
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? Color.clear : SemanticColors.glassBorder,
                        lineWidth: 1
                    )
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(count.map { ", \($0) palettes" } ?? "")")
    }

    private var addTagButton: some View {
        Button {
            showNewTagField = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.caption.weight(.medium))
                Text(L10n.libraryTagNew.localized)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(SemanticColors.gradientStart)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [SemanticColors.gradientStart.opacity(0.12), SemanticColors.gradientEnd.opacity(0.12)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(SemanticColors.gradientStart.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.libraryTagNew.localized)
    }

    private var newTagInlineField: some View {
        HStack(spacing: 6) {
            TextField(L10n.libraryTagPlaceholder.localized, text: $newTagText)
                .font(.subheadline)
                .frame(width: 120)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            newTagError != nil
                                ? SemanticColors.destructive.opacity(0.6)
                                : SemanticColors.glassBorder,
                            lineWidth: 1
                        )
                )
                .cornerRadius(8)
                .onSubmit {
                    submitNewTag()
                }
                .onChangeCompat(of: newTagText) { _ in
                    newTagError = nil
                }

            Button {
                submitNewTag()
            } label: {
                Text(L10n.libraryTagAdd.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SemanticColors.gradientStart)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button {
                cancelNewTag()
            } label: {
                Text(L10n.libraryTagCancel.localized)
                    .font(.subheadline)
                    .foregroundColor(SemanticColors.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(SemanticColors.gradientStart.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(20)
        .overlay(alignment: .top) {
            if let error = newTagError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(SemanticColors.destructive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
            )
                    .offset(y: -28)
            }
        }
    }

    private func submitNewTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            newTagError = L10n.libraryTagErrorEmpty.localized
            return
        }

        if trimmed.contains("/") {
            newTagError = L10n.libraryTagErrorSlash.localized
            return
        }

        if trimmed.count > Constants.Palette.maxTagLength {
            newTagError = L10n.libraryTagErrorMaxLength.localized
            return
        }

        if allTags.contains(trimmed) {
            // Just select it instead of erroring
            selectedTag = trimmed
            cancelNewTag()
            return
        }

        onNewTag?(trimmed)
        cancelNewTag()
    }

    private func cancelNewTag() {
        showNewTagField = false
        newTagText = ""
        newTagError = nil
    }
}
