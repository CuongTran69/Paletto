import SwiftUI
import Combine

@main
struct PalettoApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var importedPalette: ColorPalette?
    @State private var showImportedPalette = false
    @State private var showImportError = false

    private let sharingService = PaletteSharingService()

    var body: some Scene {
        WindowGroup {
            ContentView()
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
        guard let palette = sharingService.decode(url: url) else {
            showImportError = true
            return
        }

        // Save the imported palette (fire-and-forget via Task)
        let storage = PaletteStorageService()
        importedPalette = palette

        var cancellable: AnyCancellable?
        cancellable = storage.save(palette)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in cancellable?.cancel() },
                receiveValue: { [self] in
                    showImportedPalette = true
                }
            )
    }
}

