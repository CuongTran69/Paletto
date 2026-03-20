import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int
    @Binding var deepLinkPaletteID: UUID?
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            PaletteExtractionView()
                .tabItem {
                    Label(L10n.tabExtract.localized, systemImage: "paintpalette")
                }
                .tag(0)

            CameraColorPickerView()
                .tabItem {
                    Label(L10n.tabCamera.localized, systemImage: "camera")
                }
                .tag(1)

            PaletteListView(deepLinkPaletteID: $deepLinkPaletteID)
                .tabItem {
                    Label(L10n.tabLibrary.localized, systemImage: "books.vertical")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(L10n.tabSettings.localized, systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(SemanticColors.gradientStart)
        .id(loc.currentLanguage) // Force re-render on language change
    }
}

