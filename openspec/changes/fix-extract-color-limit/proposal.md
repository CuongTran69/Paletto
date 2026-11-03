## Why

The Extract tab's color selection logic has a capacity bug: `Constants.Palette.maxColorCount` is hardcoded to `8`, and the round-robin replacement in `addPickedColor()` only cycles through the last 3 slots (`[5, 6, 7]`). This means once the palette fills to `maxColorCount`, user picks are permanently locked into those 3 slots — the first 5 slots (k-means seed) are never replaceable, giving the illusion that "adding a 6th color" is blocked. Additionally, the max color capacity (8) is too restrictive for users who want larger palettes. This fix expands the capacity to 10 and changes the round-robin scope to cover the full "user-pick zone" rather than a fixed 3-slot window.

## What Changes

- **`Constants.swift`**: Change `maxColorCount` from `8` to `10`. All downstream clamps (SettingsManager, extractColors, addPickedColor) automatically adapt.
- **`PaletteExtractionViewModel.addPickedColor()`**: Expand round-robin scope from fixed 3 slots to the entire user-pick zone (`maxCount - seedCount` slots), so all user-selected colors are replaceable. Add k-means zone refill logic so deleted k-means slots can be reclaimed before round-robin kicks in.
- **`PaletteUndoRedoTests.swift`**: Add unit tests covering append-at-capacity, round-robin cycling through all user-pick slots, k-means zone refill, and undo behavior for replace operations.
- **`PaletteExtractionViewModel.extractColors()`**: Auto-adapts via constant change — no logic change needed.

## Capabilities

### New Capabilities
- `extract-color-replace`: Defines the behavior of color picking when the palette reaches max capacity — specifically: how the replace target is chosen, what happens when k-means zone has empty slots, and how undo works for replace operations.

### Modified Capabilities
- `palette-undo-redo`: The replace behavior change in `addPickedColor()` affects the undo registration for color replacement. Add scenarios for undoing replace operations.

## Impact

- **Files changed**: `Paletto/Core/Utilities/Constants.swift`, `Paletto/Features/PaletteExtraction/PaletteExtractionViewModel.swift`, `PalettoTests/PaletteUndoRedoTests.swift`
- **Auto-adapt (no code change)**: `SettingsManager.swift`, `SettingsView.swift`, `CameraColorPickerViewModel.swift`
- **Breaking**: None — the change is strictly additive from the user's perspective. Existing palettes with ≤ 8 colors remain valid.