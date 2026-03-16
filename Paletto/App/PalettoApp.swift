import SwiftUI

@main
struct PalettoApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var importedPalette: ColorPalette?
    @State private var showImportedPalette = false
    @State private var showImportError = false

    private let sharingService = PaletteSharingService()
    private let storageService = PaletteStorageService()

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .preferredColorScheme(themeManager.colorScheme)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .sheet(isPresented: $showImportedPalette) {
                    if let palette = importedPalette {
                        NavigationStack {
                            PaletteDetailView(palette: palette)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(L10n.done.localized) {
                                            showImportedPalette = false
                                        }
                                    }
                                }
                        }
                    }
                }
                .alert(L10n.shareInvalidLink.localized, isPresented: $showImportError) {
                    Button(L10n.done.localized, role: .cancel) {}
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Widget deep link: paletto://palette/{UUID} → switch to Library tab
        if url.scheme == PaletteSharingService.scheme,
           url.host == PaletteSharingService.host,
           !url.pathComponents.filter({ $0 != "/" }).isEmpty {
            selectedTab = 2
            return
        }

        // Sharing link: paletto://palette?n=NAME&c=HEX1,HEX2,...
        if let palette = sharingService.decode(url: url) {
            importedPalette = palette
            Task { @MainActor in
                do {
                    try await storageService.save(palette)
                    showImportedPalette = true
                } catch {
                    showImportError = true
                }
            }
            return
        }

        // Invalid URL
        showImportError = true
    }
}

