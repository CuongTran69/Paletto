## ADDED Requirements

### Requirement: Palette list refreshes without loading flash
When PaletteListView re-appears (e.g., after navigating back from detail), it SHALL reload data from disk without showing a loading spinner if data already exists.

#### Scenario: First load shows loading spinner
- **WHEN** PaletteListView appears for the first time with no cached palettes
- **THEN** a loading spinner is displayed until palettes are loaded from disk

#### Scenario: Re-appear after detail does not flash spinner
- **WHEN** user navigates from PaletteListView to PaletteDetailView and then navigates back
- **THEN** the palette list reloads data from disk without showing a loading spinner
- **AND** the list displays updated data (e.g., renamed palette)

#### Scenario: Re-appear after tab switch does not flash spinner
- **WHEN** user switches to another tab and then switches back to the Library tab
- **THEN** the palette list reloads data from disk without showing a loading spinner

