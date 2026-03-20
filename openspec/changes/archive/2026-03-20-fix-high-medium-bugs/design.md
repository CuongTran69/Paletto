## Context

Paletto is a native iOS SwiftUI app (iOS 16+) for color palette management. It uses MVVM architecture with protocol-oriented services. Storage is JSON file-based in Application Support. The app has a widget extension sharing data via App Group.

A codebase audit found 5 bugs across Core/Services, Features/PaletteDetail, Features/PaletteExtraction, Features/PaletteList, and App layers. These range from data loss to potential crashes.

## Goals / Non-Goals

**Goals:**
- Fix all 5 confirmed bugs without changing public API or user-facing behavior (except making broken features work correctly)
- Maintain protocol-oriented DI pattern for testability
- Minimal diff — change only what's necessary

**Non-Goals:**
- Refactoring beyond bug fixes
- Adding new features
- Changing the storage format or migration system
- Modifying the widget extension code

## Decisions

### D1: PaletteStorageService singleton pattern

**Decision**: Add `static let shared = PaletteStorageService()` and update all default parameters to use `.shared`. Keep `init` internal (not private) for test injection.

**Rationale**: A shared singleton ensures all ViewModels serialize file operations through the same `fileQueue`. Making `init` private would break existing test injection via protocol defaults.

**Alternative considered**: Dependency injection container — overkill for this app size. The protocol-based DI already works; we just need a single instance.

### D2: Name edit persistence trigger

**Decision**: Call `viewModel.updateName(viewModel.palette.name)` when user taps checkmark button or presses return (onSubmit). The `updateName` method already exists and calls `save()`.

**Rationale**: Simplest fix — reuse existing API. `updateName` sets `palette.name` (already set by TextField binding, so it's a no-op) then calls `save()`. No new API needed.

**Alternative considered**: Adding `onChange` to TextField to auto-save on every keystroke — too many disk writes, would degrade performance.

### D3: Thread-safe pixel data caching

**Decision**: Replace `UIGraphicsPushContext` + `image.draw(in:)` with `CGContext.draw(cgImage, in:)`. Use `cgImage.width/height` (pixels) instead of `image.size` (points).

**Rationale**: `CGContext.draw` is thread-safe (pure CoreGraphics). `UIGraphicsPushContext` uses a thread-local stack that is not safe from arbitrary async contexts. Since `downsampledToFit` uses `UIGraphicsImageRendererFormat(scale: 1.0)`, pixel dimensions equal point dimensions, but using `cgImage` dimensions is more correct.

**Alternative considered**: Dispatching to main thread — would block the main thread for large images, defeating the purpose of async caching.

### D4: Widget deep link navigation

**Decision**: Add `@State deepLinkPaletteID: UUID?` to PalettoApp, pass as binding through ContentView to PaletteListView. PaletteListView uses `.navigationDestination` triggered by the binding.

**Rationale**: Follows existing SwiftUI data flow pattern. The binding chain is: PalettoApp → ContentView → PaletteListView. PaletteListView loads the palette by ID from storage and navigates.

**Alternative considered**: NotificationCenter — breaks SwiftUI's declarative data flow, harder to test.

### D5: PaletteList refresh without loading flash

**Decision**: Only set `isLoading = true` when `palettes` array is empty (first load). Subsequent reloads update data silently.

**Rationale**: `onAppear` fires on NavigationStack pop-back. Showing a loading spinner every time is jarring. Data still refreshes from disk on every appear.

## Risks / Trade-offs

- **[D1] Multiple PaletteStorageService instances in tests**: Tests using `PaletteStorageService()` directly will still create separate instances. → Mitigation: Tests should inject mock via protocol, not use real service.
- **[D3] CGImage orientation**: `CGContext.draw(cgImage)` does not apply UIImage orientation transforms. → Mitigation: Images are already processed through `downsampledToFit` which uses `UIGraphicsImageRenderer` (applies orientation), so `cgImage` from the downsized image has correct orientation baked in.
- **[D4] Deep link race condition**: Widget tap may arrive before PaletteListView loads palettes from disk. → Mitigation: PaletteListView checks `deepLinkPaletteID` after `loadPalettes()` completes, not on initial appear.

