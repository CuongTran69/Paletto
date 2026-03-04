import SwiftUI

/// Library screen showing all saved palettes
struct PaletteListView: View {
    @StateObject private var viewModel = PaletteListViewModel()
    @State private var showComparison = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    Button {
                        showComparison = true
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(SemanticColors.brandGradient)
                    }
                    .accessibilityLabel(L10n.comparisonTitle.localized)
                }
            }
            .sheet(isPresented: $showComparison) {
                PaletteComparisonView()
            }
            .onAppear {
                viewModel.loadPalettes()
            }
        }
    }

    // MARK: - Subviews

    private var paletteList: some View {
        ScrollView {
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
            .padding(.top, Constants.UI.smallPadding)
        }
    }

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
}

/// Row view for a single palette in the list — glass card style
struct PaletteRowView: View {
    let palette: ColorPalette

    private var dominantColor: Color {
        palette.colors.first?.color ?? SemanticColors.gradientStart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Color strip — taller with colored shadows
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

            HStack {
                Text(palette.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(SemanticColors.primaryText)
                Spacer()
                Text(palette.formattedDate)
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
        .shadow(color: dominantColor.opacity(0.12), radius: Constants.UI.shadowRadiusMedium, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.libraryRowA11y.localized(args: [
            "name": palette.name,
            "count": "\(palette.colorCount)",
            "date": palette.formattedDate
        ]))
    }
}

