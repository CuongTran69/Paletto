# Tasks: Palette Undo/Redo

## 1. PalettoApp — Enable UndoManager

- [x] 1.1 Add `.isUndoEnabled(true)` on `WindowGroup` in `PalettoApp.swift` — chained OUTSIDE the `WindowGroup { }` closure, on the Scene itself (iOS 16+). ← (verify: build succeeds, undo buttons respond in simulator)

## 2. PaletteDetailViewModel — Coalescing + Contrast Matrix

- [x] 2.1 Add coalescing timer properties to `PaletteDetailViewModel`: `private var roleChangeCoalesceTimer: Timer?`, `private var pendingRoleChange: (colorId: UUID, previousRole: ColorRole?)?`, `private var pendingRoleChangeCount: Int = 0`
- [x] 2.2 Add `private func commitPendingRoleChange()` method per the design doc — captures accumulated state, calls `beginUndoGrouping()`, restores original role, registers undo closure that re-applies role + calls `updateContrastMatrix()` + `save()`, calls `endUndoGrouping()`, sets action name from `pendingRoleChangeCount`, resets all pending state
- [x] 2.3 Refactor `updateRole(for:to:)` to use the coalescing timer — invalidate existing timer, store pending state, schedule new 0.5s timer, apply role change immediately (no registerUndo in this path) ← (verify: rapid role changes within 0.5s produce single undo, contrast matrix correct after timer fires)
- [x] 2.4 Add `updateContrastMatrix()` call to the undo closure in `updateRole(for:to:)` non-coalesced path (the direct `registerUndo` block)
- [x] 2.5 Add `updateContrastMatrix()` call to the undo closure in `autoAssignRoles()` ← (verify: undoing auto-assign restores contrast matrix to pre-auto state)
- [x] 2.6 Add `updateContrastMatrix()` call to the undo closure in `applyFix(_:at:)` ← (verify: undoing contrast fix restores matrix to pre-fix state)
- [x] 2.7 Add `updateContrastMatrix()` call to the undo closure in `updateName(_:)`

## 3. PaletteDetailView — Verify Redo Button

- [x] 3.1 Verify Redo button in the leading toolbar slot already has a dynamic accessibility label using `undoManager?.redoActionName` ← (verify: open Detail view, check accessibility inspector shows "Redo \(actionName)" not static "Redo")
- [x] 3.2 Verify `triggerHapticIfEnabled()` is called on Redo button tap ← (verify: with haptics enabled, undo then redo produces two haptic taps)

## 4. PaletteExtractionView — Add Redo Button

- [x] 4.1 Add a `Redo` button styled identically to the existing Undo button (same glass card style, `buttonStyle(.plain)`, `opacity(0.4)` when disabled) positioned next to or below the Undo button in the extraction view ← (verify: Redo button appears below palette strip alongside Undo when colors are non-empty)
- [x] 4.2 Wire Redo button tap: call `triggerHapticIfEnabled()` then `undoManager?.redo()` ← (verify: with haptics enabled, Redo tap produces light haptic)
- [x] 4.3 Set Redo button disabled state: `.disabled(undoManager?.canRedo != true)` ← (verify: button is dimmed after undo when redo available, re-enabled after redo)
- [x] 4.4 Add dynamic accessibility label: `accessibilityLabel((undoManager?.redoActionName).map { "Redo \($0)" } ?? "Redo")` ← (verify: accessibility inspector shows correct label)

## 5. PaletteExtractionViewModel — Coalescing for Picks

- [x] 5.1 Add coalescing timer properties: `private var pickCoalesceTimer: Timer?`, `private var pendingPicks: [PaletteColor] = []`, `private var initialPickState: [PaletteColor]?`
- [x] 5.2 Refactor `addPickedColor()` to capture `extractedColors` state before mutation, cancel/restart 0.5s timer, store snapshot, apply change immediately, defer `registerUndo` until timer fires
- [x] 5.3 Implement `commitPendingPicks()` in `PaletteExtractionViewModel` — registers one undo group restoring `initialPickState`, clears pending state

## 6. Unit Tests — PaletteUndoRedoTests

- [x] 6.1 Create `PaletteUndoRedoTests.swift` in `PalettoTests/`
- [x] 6.2 Test: `testUndoManagerDisabledOnSwift5` — build verification that removing `#if swift(>=6.0)` guard does not break Swift 5 builds (compile-time only)
- [x] 6.3 Test: `testCoalescingTimerRegistersOneUndoForRapidRoleChanges` — create ViewModel with test palette, inject mock UndoManager, call `updateRole` 3× rapidly, assert `registerUndo` called once ← (verify: `undoManager.registerUndoCount == 1` after 3 rapid calls)
- [x] 6.4 Test: `testCoalescingTimerRegistersSeparateUndosWhenOutsideWindow` — use `XCTestExpectation` with 0.6s wait, assert `registerUndo` called 3 times ← (verify: each role change outside 0.5s window registers its own undo)
- [x] 6.5 Test: `testContrastMatrixRecalculatedAfterUndo` — call `updateRole`, trigger undo, assert `contrastMatrix` reflects pre-change state ← (verify: matrix state before equals matrix state after undo)
- [x] 6.6 Test: `testAllPaletteDetailMethodsRegisterUndo` — call each mutation method (role, name, auto-assign, apply-fix) in isolation, assert `registerUndo` called exactly once per call ← (verify: each method produces exactly one undo registration)
- [x] 6.7 Test: `testExtractionMethodsRegisterUndo` — call `addPickedColor`, `removeColor`, `moveColor`, assert `registerUndo` called once per method ← (verify: add/remove/reorder each produce one undo)
- [x] 6.8 Test: `testNilUndoManagerDoesNotCrash` — inject nil UndoManager, call all mutation methods, assert no crash and palette is still mutated ← (verify: operations succeed without undoManager, buttons stay disabled)
- [x] 6.9 Test: `testExtractionRedoButtonDisabledWhenNoRedo` — extract colors, assert Redo button `isEnabled == false` initially ← (verify: button renders dimmed)
- [x] 6.10 Test: `testExtractionRedoEnabledAfterUndo` — extract color, undo, assert Redo button `isEnabled == true` ← (verify: button becomes active after undo)
