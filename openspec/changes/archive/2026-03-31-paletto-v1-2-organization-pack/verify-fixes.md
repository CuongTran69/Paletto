## [2026-03-31] Round 1 (from spx-apply auto-verify)

### spx-verifier
- Fixed CRITICAL-1: `SelectWidgetPaletteIntent.perform()` now loads full palette via `PaletteQueryStorage.shared.loadById(id)` to extract actual `hexColors` and `colorRoles`. Uses `JSONEncoder` instead of `JSONSerialization`. Written to correct `widget_{kind}` UserDefaults key.
- Fixed CRITICAL-2: `autoAssignRoles()` no longer calls `performUndoGroup` (which incorrectly re-ran `assignRoles`). Now uses only `registerUndo` (which correctly restores `previousColors`) followed by single `assignRoles` call.
- Fixed WARNING-1/2/3: `createFolderSheet` — added `createFolderError` state variable, `isCreateFolderSaveDisabled` computed property, error display, disabled when max folder count reached.
- Fixed WARNING-2: `createFolderSheet` — shows `L10n.libraryFolderErrorMaxLength` inline when name exceeds 100 chars.
- Fixed WARNING-3: `renameFolderSheet` — added `renameFolderError` state variable, `isRenameFolderSaveDisabled` computed property, error display for max-length and duplicate names.
- Fixed WARNING-4: `PaletteRowView` tag chips — added `.accessibilityLabel("Tag: \(tag)")` to each chip and `.accessibilityLabel("\(palette.tags.count - 5) more tags")` to overflow badge.
- Fixed SUGGESTION-1: `PaletteDetailViewModel.addTag()` — replaced hardcoded `"Tag already exists."` with `L10n.libraryTagErrorDuplicate.localized`. Added `libraryTagErrorDuplicate` to `LocalizationKeys.swift`, `en.json`, and `vi.json`.
- Fixed SUGGESTION-2: `FolderRowView` count badge — replaced `glassBorder.opacity(0.3)` with `Color(.systemGray5)` for guaranteed visibility under `accessibilityReduceTransparency`.
- Fixed SUGGESTION-3: `SelectWidgetPaletteIntent.perform()` — replaced `JSONSerialization` with `JSONEncoder` with `.iso8601` date encoding strategy, consistent with rest of codebase.

### spx-arch-verifier
- No issues found. Architecture checks passed.

### spx-uiux-verifier
- Fixed SUGGESTION-2: Count badge visibility under `accessibilityReduceTransparency`.
- Fixed WARNING-4: Tag chip accessibility labels.
- All other UI/UX checks passed.

## [2026-03-31] Round 2 (from spx-apply auto-verify)

### spx-arch-verifier
- Fixed CRITICAL-A: `PaletteQueryStorage.palettesDirectory` now uses `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` to resolve the shared App Group container. Falls back to standard Application Support only if the container is unavailable. This ensures widget extension reads palette files from the same location the main app writes to.
- Fixed CRITICAL-B: `updateRole`, `applyFix`, `updateName` in `PaletteDetailViewModel` — replaced `performUndoGroup` with manual `beginUndoGrouping()` → mutation → `registerUndo` → `endUndoGrouping()` → `setActionName()`. Now state is mutated INSIDE the undo group, so undo correctly reverts to previous state and redo correctly re-applies the new state. The confusing first-undo-no-op is resolved.

### spx-verifier
- Re-confirmed all round 1 fixes: still clean.

### spx-uiux-verifier
- Re-confirmed all round 1 fixes: still clean.
