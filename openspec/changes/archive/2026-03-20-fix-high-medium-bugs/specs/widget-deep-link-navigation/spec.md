## ADDED Requirements

### Requirement: Widget deep link navigates to specific palette
When the user taps a widget showing a palette, the app SHALL navigate to that specific palette's detail view in the Library tab.

#### Scenario: Widget tap opens specific palette
- **WHEN** user taps a widget with URL `paletto://palette/{UUID}`
- **THEN** the app switches to the Library tab and navigates to PaletteDetailView for the palette with that UUID

#### Scenario: Widget tap with invalid UUID
- **WHEN** user taps a widget with URL `paletto://palette/{invalid-string}`
- **THEN** the app switches to the Library tab without navigating to a specific palette

#### Scenario: Widget tap when palette was deleted
- **WHEN** user taps a widget for a palette that no longer exists in storage
- **THEN** the app switches to the Library tab without navigating (palette not found)

#### Scenario: Deep link arrives before palette list loads
- **WHEN** the widget deep link URL is received and PaletteListView has not yet finished loading palettes
- **THEN** the navigation to the specific palette occurs after palettes finish loading

