## 1. Constants

- [x] 1.1 Change `maxColorCount` from `8` to `10` in `Paletto/Core/Utilities/Constants.swift` ← (verify: all other enforcement points use this constant — SettingsManager, SettingsView, extractColors, addPickedColor, CameraColorPickerViewModel)

## 2. PaletteExtractionViewModel — Round-robin and K-means Refill

- [x] 2.1 Refactor `addPickedColor()` round-robin logic: replace `let replaceRange = min(3, maxCount)` with `let userPickSlotCount = maxCount - seedCount` and `let targetIndex = seedCount + (replaceIndex % userPickSlotCount)` ← (verify: targetIndex never falls below seedCount, round-robin cycles through all user-pick slots)
- [x] 2.2 Add k-means zone refill branch before round-robin: check `deletedKMeansSlotIndex` to find the deleted k-means slot position, fill it with insert+removeLast instead of nil-guard on array ← (verify: when k-means slot is deleted, new pick fills that specific index before cycling to user-pick zone)
- [x] 2.3 Add `let seedCount = settingsManager.defaultColorCount` at top of `addPickedColor()` — both branches use it ← (verify: seedCount is correctly read from injected settingsManager, not hard-coded)
- [x] 2.4 Ensure `replaceIndex` is reset to `0` in append and refill paths (existing behavior preserved after refactor)

## 3. Undo Registration for Replace Operations

- [x] 3.1 Verify existing undo registration in replace branch captures `extractedColors[targetIndex]` as `previousColor` ← (verify: undo restores the color that was at targetIndex before replace, not the k-means original)
- [x] 3.2 Verify undo group label uses `L10n.libraryUndoAddColor` (existing constant, no change needed)
- [x] 3.3 K-means refill branch registers undo that restores the deleted slot's original color via `deletedKMeansSlotColor` closure capture — undo clears the refill state and restores previousColor

## 4. Auto-adapt Verification (No Code Change Needed)

- [x] 4.1 Verify `SettingsManager.defaultColorCount` setter clamps correctly: `min(max(newValue, minColorCount=3), maxColorCount=10)` — range becomes `[3, 10]` automatically ← (verified by code inspection: L20 uses `Constants.Palette.maxColorCount`)
- [x] 4.2 Verify `SettingsView.swift` Stepper range uses `Constants.Palette.minColorCount...Constants.Palette.maxColorCount` — auto-widens to [3...10] ← (verified by code inspection: L83 uses both constants)
- [x] 4.3 Verify `extractColors()` append guard at L78 (`count < maxColorCount`) allows up to 10 colors ← (verified by code inspection: L81 uses `Constants.Palette.maxColorCount`)

## 5. Unit Tests

- [x] 5.1 Add test for `addPickedColor()` when `extractedColors.count < maxCount`: new color is appended ← (verify: count increments by 1, color is last element)
- [x] 5.2 Add test for `addPickedColor()` when palette is full and k-means zone has no empty slots: round-robin replaces in user-pick zone (slots ≥ seedCount) ← (verify: slot 0-4 never replaced, slots 5-9 cycle in order)
- [x] 5.3 Add test for `addPickedColor()` when k-means zone has an empty slot (e.g., slot 2 deleted): new pick fills slot 2 ← (verify: refillIndex == 2, not in user-pick zone)
- [x] 5.4 Add test for round-robin cycling through all user-pick slots: pick 6 colors at max, verify slots 5→6→7→8→9→5 in sequence ← (verify: replaceIndex cycles correctly)
- [x] 5.5 Add test for undo after replace: pick color at max (replaces slot 5), undo, verify slot 5 restores previous color ← (verify: palette count stays at max, slot 5 has previousColor)
- [x] 5.6 Add test for undo k-means refill: delete slot 2, pick at max (fills slot 2), undo, verify slot 2 restores original ← (verify: k-means zone refilled correctly)