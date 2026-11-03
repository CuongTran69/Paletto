# Proposal: Palette Undo/Redo

## Why

Palette editing operations — changing color roles, renaming palettes, auto-assigning roles, applying contrast fixes in Palette Detail, and picking/removing/reordering colors during Palette Extraction — are currently permanent one-way actions. Users making mistakes have no recourse. Undo/Redo is a fundamental usability expectation for any editing interface. The OpenSpec spec `palette-undo-redo/spec.md` defines the requirements, but the implementation scaffolding (UndoManager wiring, button placement, coalescing logic) is incomplete.

## What Changes

- **PalettoApp.swift**: Remove the `#if swift(>=6.0)` guard around `isUndoEnabled = true`. The API is available in iOS 16 / Swift 5.x — the guard incorrectly blocks undo for all iOS 15 users.
- **PaletteDetailViewModel**: Complete undo registration for all palette mutation operations (change role, rename, auto-assign roles, apply contrast fix). Add coalescing timer for rapid role changes — changes within 0.5s collapse into one undo step. Recalculate contrast matrix in undo closures after state restoration.
- **PaletteDetailView**: Undo/Redo toolbar buttons already exist in the leading toolbar slot. Verify Redo button uses a dynamic label (`"Redo \(redoActionName)"`) matching the existing Undo button pattern. Ensure haptic fires on both undo and redo.
- **PaletteExtractionViewModel**: Add undo registration for `addPickedColor` (already uses `performUndoGroup` helper — confirm all paths). Add coalescing timer for rapid picks.
- **PaletteExtractionView**: Undo button already exists. Add Redo button with matching style, disabled/opacity-0.4 when no redo available. Add dynamic accessibility label.
- **New test file**: `PaletteUndoRedoTests.swift` covering coalescing timer behavior, undo registration per method, redo state, and nil undoManager safety.
- Tag add/remove operations intentionally **excluded** from undo — tags are metadata and the spec explicitly does not require undo for tag changes.

## Capabilities

### New Capabilities

- `palette-undo-redo`: Full undo/redo support for palette editing operations in Palette Detail and Palette Extraction, including coalescing of rapid changes and haptic feedback.

### Modified Capabilities

*(none — no existing spec requirements are being changed. The existing `palette-undo-redo/spec.md` is the source of truth for requirements.)*

## Impact

- **Files modified**: `PalettoApp.swift`, `PaletteDetailViewModel.swift`, `PaletteDetailView.swift`, `PaletteExtractionViewModel.swift`, `PaletteExtractionView.swift`
- **Files created**: `PaletteUndoRedoTests.swift`
- **No API or data model changes** — all work is in-memory, using iOS native `UndoManager`
- **No dependency additions** — uses existing `UndoManager+Helpers.swift` helper and `L10n` localization keys
