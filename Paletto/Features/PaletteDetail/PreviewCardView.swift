import SwiftUI

/// Available preview layout styles
enum PreviewStyle: String, CaseIterable, Identifiable {
    case appCard
    case dashboard
    case blogPost

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appCard: return L10n.previewStyleApp.localized
        case .dashboard: return L10n.previewStyleDashboard.localized
        case .blogPost: return L10n.previewStyleBlog.localized
        }
    }
}

/// Preview card showing how the palette colors look together (glass style)
struct PreviewCardView: View {
    let palette: ColorPalette
    var style: PreviewStyle = .appCard

    private var bgColor: Color {
        palette.color(for: .background)?.color ?? .white
    }
    private var primaryColor: Color {
        palette.color(for: .primary)?.color ?? .blue
    }
    private var secondaryColor: Color {
        palette.color(for: .secondary)?.color ?? .gray
    }
    private var accentColor: Color {
        palette.color(for: .accent)?.color ?? .orange
    }
    private var textColor: Color {
        palette.color(for: .text)?.color ?? .black
    }

    var body: some View {
        Group {
            switch style {
            case .appCard:
                appCardLayout
            case .dashboard:
                dashboardLayout
            case .blogPost:
                blogPostLayout
            }
        }
        .padding(Constants.UI.paddingLarge)
        .background(bgColor)
        .cornerRadius(Constants.UI.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .strokeBorder(SemanticColors.glassBorder, lineWidth: 0.5)
        )
        .shadow(color: SemanticColors.glassShadow, radius: Constants.UI.shadowRadiusMedium, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.previewA11y.localized)
    }

    // MARK: - App Card (original layout)

    private var appCardLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.previewTitle.localized)
                    .font(.title3.weight(.bold))
                    .foregroundColor(textColor)
                Spacer()
                Circle()
                    .fill(accentColor)
                    .frame(width: 36, height: 36)
                    .shadow(color: accentColor.opacity(0.3), radius: 4, y: 2)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(bgColor)
                    )
            }

            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(primaryColor)
                .frame(height: 44)
                .shadow(color: primaryColor.opacity(0.25), radius: 4, y: 2)
                .overlay(
                    Text(L10n.previewButton.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(bgColor)
                )

            Text(L10n.previewBody.localized)
                .font(.subheadline)
                .foregroundColor(textColor)

            HStack(spacing: 8) {
                let tags = [L10n.previewTag1.localized, L10n.previewTag2.localized, L10n.previewTag3.localized]
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(secondaryColor.opacity(0.25))
                        .foregroundColor(textColor)
                        .cornerRadius(Constants.UI.smallCornerRadius)
                }
            }
        }
    }

    // MARK: - Dashboard layout

    private var dashboardLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Stat cards row
            HStack(spacing: 10) {
                statCard(
                    title: L10n.previewDashboardUsers.localized,
                    value: "1,284",
                    icon: "person.2.fill",
                    color: primaryColor
                )
                statCard(
                    title: L10n.previewDashboardRevenue.localized,
                    value: "$12.4k",
                    icon: "dollarsign.circle.fill",
                    color: accentColor
                )
                statCard(
                    title: L10n.previewDashboardGrowth.localized,
                    value: "+24%",
                    icon: "arrow.up.right",
                    color: secondaryColor
                )
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L10n.previewDashboardProgress.localized)
                        .font(.caption.weight(.medium))
                        .foregroundColor(textColor)
                    Spacer()
                    Text("72%")
                        .font(.caption.weight(.bold))
                        .foregroundColor(primaryColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(secondaryColor.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(primaryColor)
                            .frame(width: geo.size.width * 0.72)
                    }
                }
                .frame(height: 8)
            }

            // Mini chart placeholder
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.previewDashboardChart.localized)
                    .font(.caption.weight(.medium))
                    .foregroundColor(textColor)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach([0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.65], id: \.self) { h in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                h == 0.9
                                    ? accentColor
                                    : primaryColor.opacity(0.6)
                            )
                            .frame(height: 50 * h)
                    }
                }
                .frame(height: 50)
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(textColor)
            Text(title)
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(Constants.UI.cornerRadius)
    }

    // MARK: - Blog Post layout

    private var blogPostLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hero image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.3), accentColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .foregroundColor(secondaryColor.opacity(0.5))
            }

            Text(L10n.previewBlogTitle.localized)
                .font(.headline.weight(.bold))
                .foregroundColor(textColor)
                .lineLimit(2)

            Text(L10n.previewBlogExcerpt.localized)
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.8))
                .lineLimit(3)

            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(bgColor)
                    )
                Text(L10n.previewBlogAuthor.localized)
                    .font(.caption.weight(.medium))
                    .foregroundColor(textColor)
                Spacer()
                Text(L10n.previewBlogDate.localized)
                    .font(.caption)
                    .foregroundColor(secondaryColor)
            }

            Text(L10n.previewBlogReadMore.localized)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(primaryColor)
        }
    }
}

