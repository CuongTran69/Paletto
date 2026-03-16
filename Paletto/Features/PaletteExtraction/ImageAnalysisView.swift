import SwiftUI

/// Image analysis view — shows dominant colors, warm/cool ratio, distributions, mood
struct ImageAnalysisView: View {
    let result: ImageAnalysisResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.paddingLarge) {
                    dominantColorsSection
                    warmCoolSection
                    saturationSection
                    brightnessSection
                    moodSection
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.analysisTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.done.localized) { dismiss() }
                        .foregroundStyle(SemanticColors.brandGradient)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.analysisA11y.localized)
        }
    }

    // MARK: - Dominant Colors

    private var dominantColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.analysisDominant.localized, icon: "paintpalette.fill")

            ForEach(result.dominantColors) { item in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .fill(item.color.color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                        )

                    Text(item.color.hex)
                        .font(.caption.monospaced())
                        .foregroundColor(SemanticColors.primaryText)

                    Spacer()

                    // Percentage bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SemanticColors.secondaryBackground)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.color)
                                .frame(width: geo.size.width * item.percentage / 100, height: 8)
                        }
                    }
                    .frame(width: 80, height: 8)

                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundColor(SemanticColors.secondaryText)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(Constants.UI.smallPadding)
                .background(.ultraThinMaterial)
                .cornerRadius(Constants.UI.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
                .accessibilityElement(children: .combine)
            }
        }
    }



    // MARK: - Warm/Cool Ratio

    private var warmCoolSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.analysisWarmCool.localized, icon: "thermometer.medium")

            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.orange.opacity(0.7))
                        .frame(width: geo.size.width * result.warmPercentage / 100)
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: geo.size.width * result.coolPercentage / 100)
                }
                .cornerRadius(Constants.UI.smallCornerRadius)
            }
            .frame(height: 24)
            .accessibilityHidden(true)

            HStack {
                Label(String(format: "%@ %.0f%%", L10n.analysisWarm.localized, result.warmPercentage),
                      systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Label(String(format: "%@ %.0f%%", L10n.analysisCool.localized, result.coolPercentage),
                      systemImage: "snowflake")
                    .font(.caption)
                    .foregroundColor(.blue)
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

    // MARK: - Saturation Distribution

    private var saturationSection: some View {
        distributionCard(
            title: L10n.analysisSaturation.localized,
            icon: "drop.fill",
            breakdown: result.saturationDistribution,
            labels: (L10n.analysisLow.localized, L10n.analysisMedium.localized, L10n.analysisHigh.localized),
            colors: (Color.gray, Color.purple.opacity(0.6), Color.purple)
        )
    }

    // MARK: - Brightness Distribution

    private var brightnessSection: some View {
        distributionCard(
            title: L10n.analysisBrightness.localized,
            icon: "sun.max.fill",
            breakdown: result.brightnessDistribution,
            labels: (L10n.analysisDark.localized, L10n.analysisMid.localized, L10n.analysisLight.localized),
            colors: (Color(.darkGray), Color.gray, Color.yellow)
        )
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L10n.analysisMood.localized, icon: "sparkles")

            Text(result.mood.localizationKey.localized)
                .font(.title2.weight(.bold))
                .foregroundStyle(SemanticColors.brandGradient)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Constants.UI.padding)
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
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

    private func distributionCard(
        title: String,
        icon: String,
        breakdown: DistributionBreakdown,
        labels: (String, String, String),
        colors: (Color, Color, Color)
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: title, icon: icon)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle().fill(colors.0)
                        .frame(width: max(1, geo.size.width * breakdown.low / 100))
                    Rectangle().fill(colors.1)
                        .frame(width: max(1, geo.size.width * breakdown.medium / 100))
                    Rectangle().fill(colors.2)
                        .frame(width: max(1, geo.size.width * breakdown.high / 100))
                }
                .cornerRadius(Constants.UI.smallCornerRadius)
            }
            .frame(height: 20)
            .accessibilityHidden(true)

            HStack {
                distributionLabel(labels.0, value: breakdown.low, color: colors.0)
                Spacer()
                distributionLabel(labels.1, value: breakdown.medium, color: colors.1)
                Spacer()
                distributionLabel(labels.2, value: breakdown.high, color: colors.2)
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

    private func distributionLabel(_ label: String, value: CGFloat, color: Color) -> some View {
        VStack(spacing: 2) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(SemanticColors.secondaryText)
            Text(String(format: "%.0f%%", value))
                .font(.caption2.weight(.bold).monospaced())
                .foregroundColor(SemanticColors.primaryText)
        }
    }
}