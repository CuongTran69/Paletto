import SwiftUI

/// Color blindness simulator view
struct ColorBlindnessView: View {
    @StateObject private var viewModel: ColorBlindnessViewModel
    @Environment(\.dismiss) private var dismiss

    init(palette: ColorPalette) {
        _viewModel = StateObject(wrappedValue: ColorBlindnessViewModel(palette: palette))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.paddingLarge) {
                    typePicker
                    if viewModel.selectedType != .normal {
                        warningBanner
                        colorGrid
                        if viewModel.hasIssues {
                            confusablePairsSection
                        }
                    }
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.blindnessTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.done.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.blindnessA11y.localized)
        }
    }



    // MARK: - Type Picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: Binding(
                get: { viewModel.selectedType },
                set: { viewModel.selectType($0) }
            )) {
                ForEach(ColorBlindnessType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.selectedType != .normal {
                Text(viewModel.selectedType.shortDescription)
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
            }
        }
    }

    // MARK: - Warning Banner

    private var warningBanner: some View {
        guard let message = viewModel.warningMessage else { return AnyView(EmptyView()) }
        let hasIssues = viewModel.hasIssues
        return AnyView(
            HStack(spacing: 10) {
                Image(systemName: hasIssues ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(hasIssues ? SemanticColors.warning : SemanticColors.success)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(SemanticColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(Constants.UI.padding)
            .background((hasIssues ? SemanticColors.warning : SemanticColors.success).opacity(0.1))
            .background(.ultraThinMaterial)
            .cornerRadius(Constants.UI.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                    .strokeBorder(
                        (hasIssues ? SemanticColors.warning : SemanticColors.success).opacity(0.3),
                        lineWidth: 1
                    )
            )
        )
    }

    // MARK: - Color Grid

    private var colorGrid: some View {
        guard let result = viewModel.simulationResult else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 12) {
                HStack {
                    Text(L10n.blindnessOriginal.localized)
                        .font(.caption.weight(.bold))
                        .foregroundColor(SemanticColors.secondaryText)
                        .frame(maxWidth: .infinity)
                    Text(L10n.blindnessSimulated.localized)
                        .font(.caption.weight(.bold))
                        .foregroundColor(SemanticColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(result.simulatedColors) { item in
                    simulatedColorRow(item)
                }
            }
        )
    }

    private func simulatedColorRow(_ item: SimulatedColor) -> some View {
        HStack(spacing: 12) {
            // Original
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(item.original.color)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                    )
                Text(item.original.hex)
                    .font(.caption2.monospaced())
                    .foregroundColor(SemanticColors.secondaryText)
            }
            .frame(maxWidth: .infinity)

            // Delta E
            VStack(spacing: 2) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(SemanticColors.secondaryText)
                Text(String(format: "%.1f", item.deltaE))
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundColor(item.deltaE > 10 ? SemanticColors.warning : SemanticColors.secondaryText)
            }
            .frame(width: 36)

            // Simulated
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(item.simulated.color)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                    )
                Text(item.simulated.hex)
                    .font(.caption2.monospaced())
                    .foregroundColor(SemanticColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Constants.UI.smallPadding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
        .accessibilityLabel(L10n.blindnessPairA11y.localized(args: [
            "hex": item.original.hex,
            "simHex": item.simulated.hex,
            "value": String(format: "%.1f", item.deltaE)
        ]))
    }

    // MARK: - Confusable Pairs

    private var confusablePairsSection: some View {
        guard let result = viewModel.simulationResult else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(SemanticColors.warning)
                    Text(L10n.blindnessConfusable.localized)
                        .font(.headline.weight(.semibold))
                }

                ForEach(result.confusablePairs) { pair in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                            .fill(pair.color1.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                    .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                            )

                        Text(pair.color1.hex)
                            .font(.caption2.monospaced())
                            .foregroundColor(SemanticColors.secondaryText)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption2)
                            .foregroundColor(SemanticColors.warning)

                        Text(pair.color2.hex)
                            .font(.caption2.monospaced())
                            .foregroundColor(SemanticColors.secondaryText)

                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                            .fill(pair.color2.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                    .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                            )

                        Spacer()

                        Text(String(format: "ΔE %.1f", pair.simulatedDeltaE))
                            .font(.caption2.weight(.bold))
                            .foregroundColor(SemanticColors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(SemanticColors.warning.opacity(0.12))
                            .cornerRadius(Constants.UI.smallCornerRadius)
                    }
                    .padding(Constants.UI.smallPadding)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .strokeBorder(SemanticColors.warning.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        )
    }
}