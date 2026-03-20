## 1. PaletteStorageService Singleton (Fix #7)

- [x] 1.1 Add `static let shared = PaletteStorageService()` to PaletteStorageService
- [x] 1.2 Update PaletteExtractionViewModel default parameter to use `.shared`
- [x] 1.3 Update CameraColorPickerViewModel default parameter to use `.shared`
- [x] 1.4 Update PaletteListViewModel default parameter to use `.shared`
- [x] 1.5 Update PaletteDetailViewModel default parameter to use `.shared`
- [x] 1.6 Update PaletteComparisonViewModel default parameter to use `.shared`
- [x] 1.7 Update PalettoApp to use `PaletteStorageService.shared` instead of local instance ← (verify: all ViewModels and PalettoApp reference .shared, no more `PaletteStorageService()` as default except in test code)

## 2. Palette Name Edit Persistence (Fix #5)

- [x] 2.1 Add save call in PaletteDetailView checkmark button action: call `viewModel.updateName(viewModel.palette.name)` after setting `editingName = false`
- [x] 2.2 Add save call in PaletteDetailView onSubmit handler: call `viewModel.updateName(viewModel.palette.name)` after setting `editingName = false` ← (verify: editing name and confirming via checkmark or return persists to disk, navigating back to Library shows updated name)

## 3. Thread-Safe Pixel Data Caching (Fix #4)

- [x] 3.1 Rewrite `buildPixelData` in PaletteExtractionViewModel to use `cgImage.width/height` instead of `image.size`
- [x] 3.2 Replace `UIGraphicsPushContext` + `image.draw(in:)` with `CGContext.draw(cgImage, in:)` in `buildPixelData` ← (verify: no UIKit graphics context APIs in buildPixelData, uses only CGContext.draw, pixel dimensions from cgImage)

## 4. Widget Deep Link Navigation (Fix #2)

- [x] 4.1 Add `@State private var deepLinkPaletteID: UUID?` to PalettoApp
- [x] 4.2 Update `handleIncomingURL` in PalettoApp to parse UUID from widget deep link path and set `deepLinkPaletteID`
- [x] 4.3 Pass `deepLinkPaletteID` binding from PalettoApp to ContentView
- [x] 4.4 Update ContentView to accept and forward `deepLinkPaletteID` binding to PaletteListView
- [x] 4.5 Update PaletteListView to accept `deepLinkPaletteID` binding
- [x] 4.6 Add navigation logic in PaletteListView: when `deepLinkPaletteID` is set and palettes are loaded, load palette by ID and navigate to PaletteDetailView, then clear the binding ← (verify: tapping widget navigates to specific palette detail, invalid UUID falls back to Library tab, deleted palette falls back to Library tab)

## 5. PaletteList Refresh Without Loading Flash (Fix #8)

- [x] 5.1 Update `loadPalettes()` in PaletteListViewModel to only set `isLoading = true` when `palettes` array is empty ← (verify: first load shows spinner, subsequent re-appears reload data silently without spinner flash)

