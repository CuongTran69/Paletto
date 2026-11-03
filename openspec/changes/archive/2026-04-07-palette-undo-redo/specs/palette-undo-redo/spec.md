# Palette Undo/Redo — Delta Specification

> This file tracks implementation progress against the requirements defined in the parent spec: `openspec/specs/palette-undo-redo/spec.md`. All requirements here are sourced from that spec. This delta confirms the implementation completeness and captures implementation-specific clarifications.

## ADDED Requirements

### Requirement: Contrast matrix recalculation after undo
When an undo operation restores palette state that includes color or role changes, the contrast matrix SHALL be recalculated immediately after the state restoration.

#### Scenario: Undo role change recalculates matrix
- **WHEN** user changes a color's role from `"Primary"` to `"Accent"`
- **AND** taps Undo
- **THEN** the color's role reverts to `"Primary"`
- **AND** the contrast matrix reflects the restored state

#### Scenario: Undo contrast fix recalculates matrix
- **WHEN** user applies a contrast fix to color at index 2
- **AND** taps Undo
- **THEN** the color reverts to its hex value and role before the fix
- **AND** the contrast matrix reflects the restored state

### Requirement: Palette Extraction Redo button
Palette Extraction view SHALL display a Redo button alongside the Undo button when `extractedColors` is non-empty. The Redo button SHALL be disabled with opacity 0.4 when no redo actions are available. The Redo button SHALL use a dynamic accessibility label reflecting the current redo action name.

#### Scenario: Redo button visible when redo available
- **WHEN** `extractedColors` is non-empty
- **AND** a user action has been undone
- **THEN** a Redo button is visible below the palette strip
- **AND** the button has a dynamic accessibility label: "Redo \(redoActionName)"

#### Scenario: Redo button disabled when no redo
- **WHEN** `extractedColors` is non-empty
- **AND** no actions have been undone in the current session
- **THEN** the Redo button is rendered but visually dimmed (opacity 0.4)
- **AND** the button is disabled

### Requirement: Palette Extraction coalescing
Rapid consecutive picks (addPickedColor) of the same type SHALL be coalesced into a single undo group if they occur within 0.5 seconds.

#### Scenario: Rapid picks coalesced
- **WHEN** user picks 3 colors within 0.5 seconds
- **AND** taps Undo once
- **THEN** all 3 picks are undone (palette reverts to state before the first pick)

## Source Reference

All other requirements for this change are defined in:

```
openspec/specs/palette-undo-redo/spec.md
```

Requirements implemented (confirmed against main spec):

| Requirement ID | Source | Status |
|---|---|---|
| UndoManager enabled | spec.md | ⚠️ Partial — Swift 6 guard needs removal |
| Undo in Palette Detail (role, name, auto-assign, contrast fix) | spec.md | ⚠️ Partial — coalescing and contrast matrix recalc missing |
| Redo in Palette Detail | spec.md | ✅ Already implemented |
| Undo in Palette Extraction (add, remove, reorder) | spec.md | ✅ Already implemented |
| Redo in Palette Extraction | spec.md | ❌ Missing — Redo button not yet added |
| Undo button state (disabled, dynamic label) | spec.md | ✅ Already implemented |
| Undo button placement | spec.md | ✅ Already implemented |
| Undo registration coalescing | spec.md | ❌ Missing — coalescing timer not implemented |
| Delete not undoable | spec.md | ✅ Already implemented (no registration) |
| Haptic feedback on undo/redo | spec.md | ⚠️ Partial — exists in Detail, missing in Extraction redo |
