import SwiftUI

/// Side-by-side palette comparison view
struct PaletteComparisonView: View {
    @StateObject private var viewModel = PaletteComparisonViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.paddingLarge) {
                    palettePickers
                    if viewModel.comparisonResult != nil {
                        summarySection
                        comparisonPairs
                    } else if viewModel.selectedPalette1 != nil || viewModel.selectedPalette2 != nil {
                        hintText
                    }
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.comparisonTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.done.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
                if viewModel.selectedPalette1 != nil && viewModel.selectedPalette2 != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.swapPalettes()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundStyle(SemanticColors.brandGradient)
                        }
                    }
                }
            }
            .onAppear { viewModel.loadPalettes() }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.comparisonA11y.localized)
        }
    }



    // MARK: - Palette Pickers

    private var palettePickers: some View {
        VStack(spacing: 12) {
            palettePicker(
                title: L10n.comparisonSelectFirst.localized,
                selection: viewModel.selectedPalette1,
                palettes: viewModel.palettes,
                onSelect: { viewModel.selectPalette1($0) }
            )

            HStack {
                Rectangle()
                    .fill(SemanticColors.border)
                    .frame(height: 1)
                Text(L10n.comparisonVs.localized)
                    .font(.caption.weight(.bold))
                    .foregroundColor(SemanticColors.secondaryText)
                Rectangle()
                    .fill(SemanticColors.border)
                    .frame(height: 1)
            }

            palettePicker(
                title: L10n.comparisonSelectSecond.localized,
                selection: viewModel.selectedPalette2,
                palettes: viewModel.availableForSecond,
                onSelect: { viewModel.selectPalette2($0) }
            )
        }
    }

    private func palettePicker(
        title: String,
        selection: ColorPalette?,
        palettes: [ColorPalette],
        onSelect: @escaping (ColorPalette) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))

            Menu {
                ForEach(palettes) { palette in
                    Button {
                        onSelect(palette)
                    } label: {
                        Label(palette.name, systemImage: "paintpalette")
                    }
                }
            } label: {
                HStack {
                    if let selected = selection {
                        HStack(spacing: 2) {
                            ForEach(selected.colors.prefix(6)) { color in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        Text(selected.name)
                            .font(.body.weight(.medium))
                            .foregroundColor(SemanticColors.primaryText)
                    } else {
                        Image(systemName: "paintpalette")
                            .foregroundStyle(SemanticColors.brandGradient)
                        Text(title)
                            .font(.body)
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
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
    }

    private var hintText: some View {
        Text(L10n.comparisonCompare.localized)
            .font(.subheadline)
            .foregroundColor(SemanticColors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.UI.paddingLarge)
    }

    // MARK: - Summary

    private var summarySection: some View {
        guard let result = viewModel.comparisonResult else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: result.overallBadge.iconName)
                        .font(.title2)
                        .foregroundColor(badgeColor(result.overallBadge))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.overallBadge.displayName)
                            .font(.headline.weight(.bold))
                        Text(L10n.comparisonAvgDeltaE.localized(args: ["value": String(format: "%.1f", result.averageDeltaE)]))
                            .font(.caption)
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                    Spacer()
                }
                .padding(Constants.UI.padding)
                .background(badgeColor(result.overallBadge).opacity(0.1))
                .background(.ultraThinMaterial)
                .cornerRadius(Constants.UI.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                        .strokeBorder(badgeColor(result.overallBadge).opacity(0.3), lineWidth: 1)
                )
            }
        )
    }

    // MARK: - Comparison Pairs

    private var comparisonPairs: some View {
        guard let result = viewModel.comparisonResult else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 12) {
                ForEach(result.pairs) { pair in
                    comparisonPairRow(pair)
                }
            }
        )
    }

    private func comparisonPairRow(_ pair: ColorComparisonResult) -> some View {
        HStack(spacing: 10) {
            // Color 1
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(pair.color1.color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )

            // Delta E info
            VStack(spacing: 2) {
                Text(L10n.comparisonDeltaE.localized(args: ["value": String(format: "%.1f", pair.deltaE)]))
                    .font(.caption.monospaced().weight(.semibold))
                Image(systemName: pair.badge.iconName)
                    .font(.caption)
                    .foregroundColor(badgeColor(pair.badge))
            }
            .frame(width: 60)

            // Color 2
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(pair.color2.color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )

            Spacer()

            // Badge label
            Text(pair.badge.displayName)
                .font(.caption2.weight(.bold))
                .foregroundColor(badgeColor(pair.badge))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor(pair.badge).opacity(0.12))
                .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
        .accessibilityLabel(L10n.comparisonPairA11y.localized(args: [
            "hex1": pair.color1.hex,
            "hex2": pair.color2.hex,
            "value": String(format: "%.1f", pair.deltaE),
            "badge": pair.badge.displayName
        ]))
    }

    // MARK: - Helpers

    private func badgeColor(_ badge: SimilarityBadge) -> Color {
        switch badge {
        case .identical: return SemanticColors.success
        case .similar: return SemanticColors.gradientStart
        case .different: return SemanticColors.warning
        case .veryDifferent: return SemanticColors.destructive
        }
    }
}