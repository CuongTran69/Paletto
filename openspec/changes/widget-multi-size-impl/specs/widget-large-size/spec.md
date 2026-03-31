# Widget Large Size

## ADDED Requirements

### Requirement: Large widget available in gallery
`PalettoWidgetBundle` SHALL include `.systemLarge` in its `supportedFamilies` configuration.

#### Scenario: Large widget available in gallery
- **WHEN** user opens the widget gallery on iOS
- **THEN** "Color Palette" widget shows three size options: Small, Medium, Large

### Requirement: Large widget layout
When the widget family is `.systemLarge`, the widget SHALL display:
1. Palette name (up to 2 lines, truncated with ellipsis)
2. Up to 8 color swatches in a 4-column grid (4 top row + 4 bottom row)
3. Each swatch shows: color fill, hex label below, role label below hex (if role is non-empty)
4. Footer text: "Paletto · Tap to open" in secondary text color

#### Scenario: Large widget with 5 colors
- **WHEN** the palette has 5 colors
- **THEN** the widget shows 5 swatches side by side (4 top + 1 bottom left)
- **AND** remaining 3 bottom swatch slots show dashed-border empty placeholders
- **AND** the footer shows "Paletto · Tap to open"

#### Scenario: Large widget with role labels
- **WHEN** the palette has colors with assigned roles (e.g., Color 0 = Background, Color 1 = Primary)
- **THEN** role labels appear below hex labels on the respective swatches

#### Scenario: Large widget with 8+ colors
- **WHEN** the palette has 8 or more colors
- **THEN** only the first 8 colors are shown

#### Scenario: Large widget with named palette
- **WHEN** the palette name is `"Spring Colors 2026"`
- **THEN** the name is displayed at the top, truncated at 2 lines if needed

### Requirement: Large widget deep link
Tapping the large widget SHALL navigate to the palette detail view via the existing URL scheme `paletto://palette/{paletteId}`.

#### Scenario: Tap large widget
- **WHEN** user taps the large widget
- **THEN** the app opens and navigates directly to the Palette Detail view for that palette

### Requirement: Large widget empty state
When no palette is set for the large widget slot, the widget SHALL display the same empty state as the small/medium widget.

#### Scenario: Empty large widget
- **WHEN** no palette has been set for the large widget slot
- **THEN** the widget shows "Set a palette in Paletto" with the palette icon

### Requirement: Widget timeline reads correct slot by size
`PaletteTimelineProvider.getTimeline()` SHALL load the palette from the correct UserDefaults key based on the widget family.

#### Scenario: Small widget loads small palette
- **WHEN** `getTimeline` is called for a small widget
- **THEN** it reads `UserDefaults[appGroup]["widget_small"]`
- **AND** the small widget displays that palette

#### Scenario: Large widget loads large palette
- **WHEN** `getTimeline` is called for a large widget
- **THEN** it reads `UserDefaults[appGroup]["widget_large"]`
- **AND** the large widget displays that palette

#### Scenario: Fallback when slot is empty
- **WHEN** the UserDefaults key for the current widget size contains no data
- **THEN** the widget shows the empty state

### Requirement: Large widget color swatch accessibility
Each color swatch in the large widget SHALL provide an accessibility label with the hex value and role name.

#### Scenario: VoiceOver on large widget swatch
- **WHEN** VoiceOver is enabled and user navigates to a swatch with hex `#FF6B6B` and role "Background"
- **THEN** VoiceOver announces: "Color #FF6B6B, Background role"
