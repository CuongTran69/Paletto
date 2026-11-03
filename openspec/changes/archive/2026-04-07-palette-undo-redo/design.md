# Design: Palette Undo/Redo

## Context

The OpenSpec spec `palette-undo-redo/spec.md` defines requirements for undo/redo across two screens: **Palette Detail** (role changes, name edits, auto-assign, contrast fixes) and **Palette Extraction** (color picks, removals, reorder). The implementation scaffolding is partially in place — `isUndoEnabled` on WindowGroup, `undoManager` property on both ViewModels, and the `performUndoGroup` helper in `UndoManager+Helpers.swift`. The missing work is the actual undo registration calls, the coalescing timer logic, and the Redo button in Palette Extraction.

## Goals / Non-Goals

**Goals:**
- Full undo/redo coverage for all 6 spec-defined operations across both screens
- Coalescing of rapid same-type changes within a 0.5s window into a single undo step
- Haptic feedback on undo/redo taps (light impact, gated by `hapticFeedbackEnabled`)
- Dynamic accessibility labels on undo/redo buttons reflecting the current action name
- Contrast matrix recalculation after undo restores palette state

**Non-Goals:**
- Undo/redo for tag add/remove (out of scope per spec)
- Undo/redo for palette deletion (intentionally permanent)
- Undo/redo for widget assignment
- Undo/redo for palette sharing/export
- Supporting iOS 15 (minimum target is iOS 16, where `isUndoEnabled` is available)

## Decisions

### Decision 1: Coalescing Timer Implementation

**Choice**: `Timer.scheduledTimer` with cancel-and-restart pattern, stored as a property on each ViewModel.

**Rationale**: UndoManager does not natively support coalescing. The approach is: on each mutation, capture the *original* state immediately, start/reset a 0.5s timer, and defer `registerUndo` until the timer fires. If the user makes another change before the timer fires, the previous capture is discarded and replaced with a fresh capture. When the timer finally fires, a single `registerUndo` call captures the accumulated delta.

```swift
// Stored on PaletteDetailViewModel:
private var roleChangeCoalesceTimer: Timer?
private var pendingRoleChange: (colorId: UUID, previousRole: ColorRole?)?
private var pendingRoleChangeCount: Int = 0

func updateRole(for colorId: UUID, to role: ColorRole) {
    // Capture immediately
    guard let index = palette.colors.firstIndex(where: { $0.id == colorId }) else { return }
    let previousRole = palette.colors[index].role

    // Cancel + restart timer
    roleChangeCoalesceTimer?.invalidate()
    pendingRoleChange = (colorId, previousRole)
    pendingRoleChangeCount += 1

    roleChangeCoalesceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
        self?.commitPendingRoleChange()
    }

    // Apply immediately (mutate palette now for instant UI feedback)
    palette.colors[index].role = role
    // No registerUndo here — deferred until timer fires
    save()
    syncPaletteToCaller()
}

private func commitPendingRoleChange() {
    guard let pending = pendingRoleChange else { return }
    let count = pendingRoleChangeCount

    undoManager?.beginUndoGrouping()
    // Restore the captured original state
    if let idx = palette.colors.firstIndex(where: { $0.id == pending.colorId }) {
        palette.colors[idx].role = pending.previousRole
    }
    undoManager?.registerUndo(withTarget: self) { target in
        // Redo: re-apply all coalesced changes
        if let idx = target.palette.colors.firstIndex(where: { $0.id == pending.colorId }) {
            target.palette.colors[idx].role = role // captured from closure
        }
        target.updateContrastMatrix()
        target.save()
    }
    undoManager?.endUndoGrouping()

    let name = count > 1
        ? L10n.libraryUndoChangeRole.localized // generic: "Change Role"
        : L10n.libraryUndoChangeRole.localized
    undoManager?.setActionName(name)

    pendingRoleChange = nil
    pendingRoleChangeCount = 0
    updateContrastMatrix()
    save()
}
```

**Alternative considered**: Using UndoManager's `groupingLevel` and `endUndoGrouping` to manually group — but UndoManager groups cannot be coalesced across time; they must be opened and closed synchronously. Timer-based deferral is the correct approach.

**Alternative considered**: Debouncing at the View layer (SwiftUI) — rejected because mutations happen in the ViewModel (not the View), and the ViewModel needs direct access to the captured state for the undo closure.

### Decision 2: Contrast Matrix Recalculation After Undo

**Choice**: Call `updateContrastMatrix()` inside every `registerUndo` closure that restores palette state.

**Rationale**: `UndoManager` calls the registered closure at undo time — i.e., *later* and *outside* the normal execution path. Any color or role change that could affect the contrast matrix must recalculate it when undone. The closures already call `save()` and `syncPaletteToCaller()` — adding `updateContrastMatrix()` is consistent with this pattern.

```swift
// In undo closure for updateRole (non-coalesced path):
undoManager?.registerUndo(withTarget: self) { target in
    if let idx = target.palette.colors.firstIndex(where: { $0.id == colorId }) {
        target.palette.colors[idx].role = previousRole
    }
    target.updateContrastMatrix()   // ← added
    target.save()
    target.syncPaletteToCaller()   // ← already present
}
```

For coalesced role changes, `updateContrastMatrix()` is called once in `commitPendingRoleChange()` after registering the undo group.

### Decision 3: Nil undoManager Safety

**Choice**: All `undoManager?.` calls are optional-chained. Operations proceed (save, sync) regardless of whether undoManager is set. Toolbar buttons are disabled when `undoManager` is nil.

**Rationale**: `undoManager` is set in `.onAppear` from `@Environment(\.undoManager)`. If the environment is nil (extremely rare in a SwiftUI WindowGroup), the app continues to function — the buttons simply stay disabled. No crash path.

### Decision 4: Redo Button Label

**Choice**: Dynamic label `"Redo \(undoManager.redoActionName ?? "")"` — same pattern as the existing Undo button label `"\(undoManager?.undoActionName ?? "")"`.

**Rationale**: The spec says "Undo button SHALL show the name of the action" — this applies equally to Redo. iOS convention is to show "Redo" alone when no action name is set. Using `redoActionName` (which returns `String?`) and falling back to an empty string keeps the button label clean: "Redo" or "Redo Edit Name".

### Decision 5: Palette Extraction Redo Button Visibility

**Choice**: Redo button is always rendered alongside Undo when `!extractedColors.isEmpty`. It is disabled (`.disabled(undoManager?.canRedo != true)`) and has `opacity(undoManager?.canRedo != true ? 0.4 : 1.0)` when no redo is available.

**Rationale**: Consistent with how the Undo button already works in Palette Extraction. No "show/hide" toggle — rendering both buttons at all times avoids layout shift. The disabled opacity communicates unavailability clearly.

## Risks / Trade-offs

**[Risk] Timer memory leak** → Mitigation: `roleChangeCoalesceTimer?.invalidate()` is called at the start of `updateRole` (cancel previous) and in `commitPendingRoleChange` (nullify after firing). Weak `self` in the timer closure prevents retain cycles.

**[Risk] Palette being modified externally while timer is pending** → Mitigation: The timer captures `pendingRoleChange` as a snapshot of the *original* state at mutation time. If another operation changes the palette before the timer fires, the pending snapshot becomes stale — but since we always cancel and restart the timer on each new mutation, the last mutation wins. This is the desired coalescing behavior.

**[Risk] iOS 15 users** → Mitigation: Removing the `#if swift(>=6.0)` guard from `isUndoEnabled`. The deployment target check is a separate concern handled by Xcode project settings — if the app targets iOS 16+, this is a no-op change.

**[Risk] Undo closures capturing stale state** → Mitigation: All undo closures capture state *at registration time* (by value, not reference) via `[weak self]` and explicit local variables. The palette mutations themselves happen immediately (not deferred), so the UI is always up-to-date. Only the undo registration is deferred.

## Open Questions

*(none — all decisions were resolved during exploration. The spec, coalescing timer approach, nil-safety strategy, and test coverage level were all confirmed with the user before creating this change.)*
