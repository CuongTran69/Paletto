# Verify Fixes Log

## [2026-04-06] Round 1 (from spx-apply auto-verify)

### spx-verifier
- Fixed: Bug in `commitPendingRoleChange()` in `PaletteDetailViewModel.swift` — the undo closure referenced `self.pendingRoleChange` inside the closure, but this is set to `nil` at line 135 *before* the closure is registered. The fix captures `pending.colorId` and `appliedRole` by value from the local `pending` variable, which is valid at registration time. The closure now correctly restores the applied role on redo.

### Build Error Fix
- Fixed: `.isUndoEnabled(true)` was chained INSIDE `WindowGroup { }` on the View — Swift sees the result as `some View` which has no `isUndoEnabled` member. Moved `.isUndoEnabled(true)` AFTER the closing `}` of `WindowGroup`, chained on the `WindowGroup` itself (the Scene). Also removed the duplicate from inside the closure (line 22). Updated task 1.1 description in tasks.md to correctly describe this fix.
