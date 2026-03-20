import SwiftUI

/// Settings screen — language, theme, general preferences (glass card style)
struct SettingsView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hapticEnabled = SettingsManager.shared.hapticFeedbackEnabled
    @State private var defaultColorCount = SettingsManager.shared.defaultColorCount
    @State private var defaultExportFormat = SettingsManager.shared.defaultExportFormat

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.padding) {
                    appearanceSection
                    languageSection
                    generalSection
                    aboutSection
                }
                .padding(.horizontal, Constants.UI.padding)
                .padding(.top, Constants.UI.smallPadding)
                .padding(.bottom, Constants.UI.paddingXL)
            }
            .background(SemanticColors.appBackground)
            .navigationTitle(L10n.settingsTitle.localized)
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        glassSection(title: L10n.settingsAppearance.localized, icon: "moon.stars.fill") {
            settingsRow(icon: "circle.lefthalf.filled", title: L10n.settingsThemeLabel.localized) {
                Picker("", selection: $themeManager.currentTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .tint(SemanticColors.gradientStart)
            }
        }
    }

    private var languageSection: some View {
        glassSection(title: L10n.settingsLanguageSection.localized, icon: "globe") {
            settingsRow(icon: "character.bubble.fill", title: L10n.settingsLanguageLabel.localized) {
                Picker("", selection: $loc.currentLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .tint(SemanticColors.gradientStart)
            }
        }
    }

    private var generalSection: some View {
        glassSection(title: L10n.settingsGeneral.localized, icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                settingsRow(icon: "hand.tap.fill", title: L10n.settingsHaptic.localized) {
                    Toggle("", isOn: $hapticEnabled)
                        .labelsHidden()
                        .tint(SemanticColors.gradientStart)
                        .onChangeCompat(of: hapticEnabled) { newValue in
                            SettingsManager.shared.hapticFeedbackEnabled = newValue
                        }
                }

                settingsRow(icon: "number.circle.fill", title: L10n.settingsColorCount.localized) {
                    Stepper("\(defaultColorCount)", value: $defaultColorCount,
                            in: Constants.Palette.minColorCount...Constants.Palette.maxColorCount)
                        .onChangeCompat(of: defaultColorCount) { newValue in
                            SettingsManager.shared.defaultColorCount = newValue
                        }
                }

                settingsRow(icon: "square.and.arrow.up.fill", title: L10n.settingsExportFormat.localized) {
                    Picker("", selection: $defaultExportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .labelsHidden()
                    .tint(SemanticColors.gradientStart)
                    .onChangeCompat(of: defaultExportFormat) { newValue in
                        SettingsManager.shared.defaultExportFormat = newValue
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        glassSection(title: L10n.settingsAbout.localized, icon: "info.circle.fill") {
            settingsRow(icon: "tag.fill", title: L10n.settingsVersion.localized) {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.subheadline)
                    .foregroundColor(SemanticColors.secondaryText)
            }
        }
    }

    // MARK: - Reusable Components

    private func glassSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SemanticColors.brandGradient)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SemanticColors.secondaryText)
            }
            .padding(.horizontal, Constants.UI.padding)
            .padding(.bottom, 10)

            content()
                .padding(Constants.UI.padding)
                .background(.ultraThinMaterial)
                .cornerRadius(Constants.UI.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                        .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
                )
        }
    }

    private func settingsRow<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(SemanticColors.brandGradient)
                .frame(width: 28)
            Text(title)
                .font(.body)
            Spacer()
            trailing()
        }
        .padding(.vertical, 4)
    }
}


