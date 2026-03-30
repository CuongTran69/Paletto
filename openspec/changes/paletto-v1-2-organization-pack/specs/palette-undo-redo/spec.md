# Palette Undo/Redo

## ADDED Requirements

### Requirement: UndoManager enabled
The app SHALL enable SwiftUI's UndoManager by setting `isUndoEnabled = true` on the `WindowGroup` in `PalettoApp`.

#### Scenario: UndoManager available in view hierarchy
- **WHEN** the app launches
- **THEN** `UndoManager` is accessible via `@Environment(\.undoManager)` in all SwiftUI views and view models

### Requirement: Undo in Palette Detail
Palette Detail view SHALL support undoing the following operations: changing a color's role, editing the palette name, auto-assigning roles, and applying a contrast fix.

#### Scenario: Undo role change
- **WHEN** user changes a color's role from `"Primary"` to `"Accent"`
- **AND** immediately taps the Undo button
- **THEN** the color's role reverts to `"Primary"`

#### Scenario: Undo name edit
- **WHEN** user changes the palette name to `"My Palette"`
- **AND** taps the Undo button
- **THEN** the palette name reverts to its previous value

#### Scenario: Undo auto-assign roles
- **WHEN** user taps "Auto Assign Roles"
- **AND** taps the Undo button
- **THEN** all color roles revert to their state before auto-assignment

#### Scenario: Undo contrast fix
- **WHEN** user applies a contrast fix to color at index 2
- **AND** taps the Undo button
- **THEN** the color reverts to its hex value and role before the fix

### Requirement: Redo in Palette Detail
Palette Detail view SHALL support redoing previously undone operations in Palette Detail.

#### Scenario: Redo after undo
- **WHEN** user changes a role and undoes it
- **AND** then taps the Redo button
- **THEN** the role change is reapplied (palette is back to modified state)

#### Scenario: Redo button disabled when no redo available
- **WHEN** the undo history is empty
- **THEN** the Redo button is disabled (visually dimmed)

### Requirement: Undo in Palette Extraction
Palette Extraction view SHALL support undoing the following operations: adding a picked color, removing a color, and reordering colors.

#### Scenario: Undo add picked color
- **WHEN** user picks a color from the magnifier (adds it to the palette)
- **AND** taps the Undo button
- **THEN** the color is removed from `extractedColors` and the palette strip updates

#### Scenario: Undo remove color
- **WHEN** user removes color at index 1
- **AND** taps the Undo button
- **THEN** the color is restored to index 1 in `extractedColors`

#### Scenario: Undo reorder colors
- **WHEN** user drags to reorder colors in the palette strip
- **AND** taps the Undo button
- **THEN** the colors revert to their previous order

### Requirement: Redo in Palette Extraction
Palette Extraction view SHALL support redoing previously undone operations.

#### Scenario: Redo after undo in extraction
- **WHEN** user removes a color and undoes it
- **AND** then taps the Redo button
- **THEN** the color is removed again

### Requirement: Undo button state
The Undo button SHALL be disabled when no undo actions are available. The button SHALL show the name of the action that will be undone (e.g., "Undo" / "Undo Add").

#### Scenario: Undo button disabled with empty history
- **WHEN** no undo actions have been recorded in the current session
- **THEN** the Undo button is disabled

### Requirement: Undo button placement
Undo/Redo buttons SHALL appear in the toolbar area of their respective screens.

#### Scenario: Palette Detail toolbar
- **WHEN** user is on the Palette Detail screen
- **THEN** Undo and Redo buttons appear in the navigation toolbar (left side)

#### Scenario: Palette Extraction toolbar
- **WHEN** `extractedColors` is non-empty
- **THEN** an Undo button appears below the palette strip

### Requirement: Undo registration coalescing
Consecutive operations of the same type (e.g., rapid role changes) SHALL be coalesced into a single undo group if they occur within 0.5 seconds.

#### Scenario: Rapid role changes coalesced
- **WHEN** user changes role from Primary→Secondary→Accent within 0.5 seconds
- **AND** taps Undo once
- **THEN** ALL three changes are undone (reverts to the state before the first change)

### Requirement: Delete palette not undoable
Deleting a palette from the Library list SHALL NOT be wrapped in an undo group. Deletion is immediate and permanent after confirmation.

#### Scenario: Delete confirmed — no undo
- **WHEN** user confirms deletion of a palette
- **THEN** the palette file is deleted from disk immediately
- **AND** no Undo operation is registered for this action

### Requirement: Haptic feedback on undo/redo
When haptic feedback is enabled in settings, tapping Undo or Redo SHALL trigger a light haptic feedback.

#### Scenario: Haptic on undo
- **WHEN** `hapticFeedbackEnabled` is true and user taps Undo
- **THEN** `UIImpactFeedbackGenerator(style: .light).impactOccurred()` is called
