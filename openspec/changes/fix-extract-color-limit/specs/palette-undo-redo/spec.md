# Palette Undo/Redo — Delta Spec

## MODIFIED Requirements

### Requirement: Undo in Palette Extraction
Palette Extraction view SHALL support undoing the following operations: adding a picked color, removing a color, reordering colors, and **replacing a color at max capacity**.

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

#### Scenario: Undo replace at max capacity
- **WHEN** palette is at max capacity (10 colors) and user picks a color that replaces an existing user-pick slot
- **AND** taps the Undo button
- **THEN** the previous color in that slot is restored
- **AND** the new picked color is NOT present in the palette

#### Scenario: Multiple replaces at max capacity, undo restores in order
- **WHEN** palette is at max (10 colors) and user picks colors that replace slots 5, then 6, then 7
- **AND** user taps Undo three times
- **THEN** first undo restores slot 7's previous color
- **AND** second undo restores slot 6's previous color
- **AND** third undo restores slot 5's previous color

#### Scenario: Undo replace followed by undo remove restores original k-means color
- **WHEN** user picks a color at max capacity (replacing slot 5)
- **AND** removes slot 2 from k-means zone
- **AND** taps Undo twice
- **THEN** first undo restores the removed color to slot 2
- **AND** second undo restores the replaced color in slot 5