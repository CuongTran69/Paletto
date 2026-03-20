## Why

The Paletto iOS app has 5 confirmed bugs (2 high severity, 3 medium severity) discovered during a codebase audit. These bugs cause data loss (palette name edits not persisting), potential crashes (UIKit API called off main thread), incomplete features (widget deep link ignores palette UUID), stale UI (palette list not refreshing properly), and thread-safety risks (multiple PaletteStorageService instances with independent serial queues).

## What Changes

- **Fix PaletteStorageService singleton**: Convert to shared singleton so all ViewModels use the same instance and serial queue, eliminating file-system race conditions.
- **Fix palette name edit persistence**: Ensure name changes in PaletteDetailView are saved to disk when the user confirms the edit.
- **Fix UIGraphicsPushContext off main thread**: Replace UIKit graphics API calls in `PaletteExtractionViewModel.buildPixelData` with thread-safe CoreGraphics API.
- **Fix widget deep link navigation**: Parse UUID from widget deep link URL and navigate to the specific palette in the Library tab.
- **Fix PaletteList refresh behavior**: Eliminate loading spinner flash on re-appear while still reloading data from disk.

## Capabilities

### New Capabilities
- `widget-deep-link-navigation`: Handle widget deep link URLs (`paletto://palette/{UUID}`) to navigate directly to a specific palette in the Library tab.

### Modified Capabilities
- `palette-storage`: PaletteStorageService becomes a singleton with `shared` instance. All ViewModels use the shared instance by default.
- `palette-detail-editing`: Name edits in PaletteDetailView are persisted to disk when the user confirms (tap checkmark or submit).
- `palette-extraction-pixel-cache`: Pixel data caching uses thread-safe CoreGraphics API instead of UIKit UIGraphicsPushContext.
- `palette-list-refresh`: PaletteListView reloads data on appear without flashing a loading spinner when data already exists.

## Impact

- **Core/Services/PaletteStorageService.swift**: Add `static let shared`, keep `init` accessible for testing.
- **All ViewModels with storage dependency**: Update default parameter from `PaletteStorageService()` to `PaletteStorageService.shared` (6 files).
- **Features/PaletteDetail/PaletteDetailView.swift**: Add save call when name editing ends.
- **Features/PaletteExtraction/PaletteExtractionViewModel.swift**: Rewrite `buildPixelData` to use CGContext.draw instead of UIGraphicsPushContext.
- **App/PalettoApp.swift**: Parse UUID from widget deep link, pass to ContentView.
- **App/ContentView.swift**: Accept and forward deep link palette ID binding.
- **Features/PaletteList/PaletteListView.swift**: Accept deep link binding, trigger navigation; conditional loading spinner.
- **Features/PaletteList/PaletteListViewModel.swift**: Conditional `isLoading` on first load only.

