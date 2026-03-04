import SwiftUI

/// Grid showing contrast ratios between all color pairs (glass style)
struct ContrastMatrixView: View {
    let colors: [PaletteColor]
    let matrix: [[ContrastResult]]
    let onFixSuggested: (Int, Int) -> Void

    private let cellSize: CGFloat = 48
    @State private var tooltipCell: TooltipCell?

    private struct TooltipCell: Identifiable {
        let row: Int
        let col: Int
        var id: String { "\(row)-\(col)" }
    }

    var body: some View {
        if colors.isEmpty || matrix.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 10) {
                // Matrix grid
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 3) {
                        // Header row
                        HStack(spacing: 3) {
                            Color.clear.frame(width: cellSize, height: cellSize)
                            ForEach(Array(colors.enumerated()), id: \.element.id) { _, color in
                                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                    .fill(color.color)
                                    .frame(width: cellSize, height: cellSize)
                                    .shadow(color: color.color.opacity(0.2), radius: 2, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                            .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                                    )
                            }
                        }

                        // Matrix rows
                        ForEach(Array(colors.enumerated()), id: \.element.id) { i, rowColor in
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                    .fill(rowColor.color)
                                    .frame(width: cellSize, height: cellSize)
                                    .shadow(color: rowColor.color.opacity(0.2), radius: 2, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                                            .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                                    )

                                ForEach(Array(colors.enumerated()), id: \.element.id) { j, _ in
                                    if i < matrix.count, j < matrix[i].count {
                                        contrastCell(result: matrix[i][j], row: i, col: j)
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

                // Legend
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        legendItem(color: .green.opacity(0.25), label: L10n.detailContrastLegendAAA.localized)
                        legendItem(color: .green.opacity(0.15), label: L10n.detailContrastLegendAA.localized)
                    }
                    HStack(spacing: 12) {
                        legendItem(color: .yellow.opacity(0.25), label: L10n.detailContrastLegendLarge.localized)
                        legendItem(color: .red.opacity(0.2), label: L10n.detailContrastLegendFail.localized)
                    }
                }
                .padding(.horizontal, Constants.UI.smallPadding)

                // Hint
                Text(L10n.detailContrastHint.localized)
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }

    private func contrastCell(result: ContrastResult, row: Int, col: Int) -> some View {
        let bgColor: Color = {
            if row == col { return Color(.systemGray5) }
            if result.passesAAA { return .green.opacity(0.25) }
            if result.passesAA { return .green.opacity(0.15) }
            if result.passesAALargeText { return .yellow.opacity(0.25) }
            return .red.opacity(0.2)
        }()
        let isShowingTooltip = Binding<Bool>(
            get: { tooltipCell?.row == row && tooltipCell?.col == col },
            set: { if !$0 { tooltipCell = nil } }
        )

        return Button {
            if !result.passesAA, row != col {
                onFixSuggested(row, col)
            }
        } label: {
            Text(row == col ? "-" : result.formattedRatio)
                .font(.caption2.monospaced().weight(.medium))
                .foregroundColor(.primary)
                .frame(width: cellSize, height: cellSize)
                .background(bgColor)
                .cornerRadius(Constants.UI.smallCornerRadius)
        }
        .disabled(row == col)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if row != col {
                        tooltipCell = TooltipCell(row: row, col: col)
                    }
                }
        )
        .popover(isPresented: isShowingTooltip, arrowEdge: .top) {
            tooltipContent(result: result, row: row, col: col)
        }
        .accessibilityLabel(
            row == col
                ? L10n.detailContrastSameColor.localized
                : L10n.detailContrastA11y.localized(args: ["ratio": result.formattedRatio, "level": result.normalTextLevel.rawValue])
        )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(.label).opacity(0.1), lineWidth: 0.5)
                )
            Text(label)
                .font(.caption2)
                .foregroundColor(SemanticColors.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private func tooltipContent(result: ContrastResult, row: Int, col: Int) -> some View {
        let fgColor = colors[row]
        let bgColor = colors[col]

        return VStack(alignment: .leading, spacing: 10) {
            // Color swatches
            HStack(spacing: 12) {
                colorLabel(color: fgColor, label: L10n.detailContrastTooltipFg.localized)
                colorLabel(color: bgColor, label: L10n.detailContrastTooltipBg.localized)
            }

            Divider()

            // Ratio
            Text(L10n.detailContrastTooltipRatio.localized(args: ["ratio": result.formattedRatio]))
                .font(.subheadline.weight(.semibold))

            // WCAG levels
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.detailContrastTooltipNormal.localized(args: ["level": result.normalTextLevel.rawValue]))
                        .font(.caption)
                        .foregroundColor(result.passesAA ? SemanticColors.success : SemanticColors.destructive)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.detailContrastTooltipLarge.localized(args: ["level": result.largeTextLevel.rawValue]))
                        .font(.caption)
                        .foregroundColor(result.passesAALargeText ? SemanticColors.success : SemanticColors.destructive)
                }
            }

            // Fix hint
            if !result.passesAA {
                Text(L10n.detailContrastTooltipFix.localized)
                    .font(.caption)
                    .foregroundColor(SemanticColors.secondaryText)
                    .italic()
            }
        }
        .padding(Constants.UI.padding)
        .frame(minWidth: 200)
        .modifier(PopoverCompactAdaptation())
    }

    private func colorLabel(color: PaletteColor, label: String) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                .fill(color.color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
            Text(label)
                .font(.caption2)
                .foregroundColor(SemanticColors.secondaryText)
            Text(color.hex)
                .font(.caption2.monospaced().weight(.medium))
        }
    }
}


/// Applies `.presentationCompactAdaptation(.popover)` on iOS 16.4+, no-op on older.
private struct PopoverCompactAdaptation: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}