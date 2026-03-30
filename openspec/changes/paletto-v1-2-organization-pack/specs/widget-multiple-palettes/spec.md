# Widget Multiple Palettes

## ADDED Requirements

### Requirement: Widget config data structure
The app SHALL store widget configuration in App Group UserDefaults with one entry per widget size (small, medium, large). Each entry holds the `WidgetPalette` data and an `updatedAt` timestamp.

#### Scenario: Set large widget palette
- **WHEN** user selects a palette for the large widget size
- **THEN** `UserDefaults[appGroup]["widget_large"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

#### Scenario: Set medium widget palette
- **WHEN** user selects a palette for the medium widget size
- **THEN** `UserDefaults[appGroup]["widget_medium"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

#### Scenario: Set small widget palette
- **WHEN** user selects a palette for the small widget size
- **THEN** `UserDefaults[appGroup]["widget_small"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

### Requirement: Set as Widget menu with size selection
The "Set as Widget" action in Palette Detail SHALL present an action sheet with three options: "Small Widget", "Medium Widget", "Large Widget". Tapping an option sets that palette as the display palette for the chosen widget size.

#### Scenario: Set as small widget
- **WHEN** user taps "Set as Widget" → "Small Widget"
- **THEN** the current palette is saved to the small widget slot
- **AND** `WidgetCenter.shared.reloadTimelines(ofKind:)` is called
- **AND** a confirmation appears: "Set as Small Widget"

#### Scenario: Set as medium widget
- **WHEN** user taps "Set as Widget" → "Medium Widget"
- **THEN** the current palette is saved to the medium widget slot
- **AND** `WidgetCenter.shared.reloadTimelines(ofKind:)` is called

#### Scenario: Set as large widget
- **WHEN** user taps "Set as Widget" → "Large Widget"
- **THEN** the current palette is saved to the large widget slot
- **AND** `WidgetCenter.shared.reloadTimelines(ofKind:)` is called

### Requirement: AppIntent widget configuration (iOS 17+)
The app SHALL provide a `SelectWidgetPaletteIntent` AppIntent that allows users to select a palette for each widget size directly from the iOS widget configuration UI (long-press → Edit Widget).

#### Scenario: Configure widget via AppIntent on iOS 17+
- **WHEN** user long-presses the Paletto widget and taps "Edit Widget"
- **THEN** the widget configuration UI shows a palette picker listing all saved palettes
- **AND** user selects a palette
- **THEN** the selected palette is written to the appropriate widget slot
- **AND** `WidgetCenter.shared.reloadTimelines(ofKind:)` is called

#### Scenario: AppIntent on iOS 16
- **WHEN** user runs on iOS 16 and long-presses the Paletto widget
- **THEN** the widget configuration UI shows the default placeholder (no custom AppIntent picker)
- **AND** user uses the in-app "Set as Widget" menu instead

### Requirement: Widget loads correct palette per size
`PaletteTimelineProvider.getTimeline()` SHALL load the palette for the current widget size from the correct UserDefaults key based on the `family` parameter.

#### Scenario: Small widget loads small palette
- **WHEN** `getTimeline` is called for a small widget
- **THEN** it reads `UserDefaults[appGroup]["widget_small"]`
- **AND** the small widget displays that palette

#### Scenario: Large widget loads large palette
- **WHEN** `getTimeline` is called for a large widget
- **THEN** it reads `UserDefaults[appGroup]["widget_large"]`
- **AND** the large widget displays that palette

#### Scenario: Fallback when slot is empty
- **WHEN** `UserDefaults[appGroup]["widget_small"]` contains no data
- **THEN** the widget shows the empty state

### Requirement: Multiple widget instances
The system SHALL support having multiple widget instances of different sizes on the same Home Screen, each displaying the palette configured for its respective size slot.

#### Scenario: Small and large widget on same screen
- **WHEN** user has a small widget showing palette A and a large widget showing palette B
- **THEN** the small widget displays palette A correctly
- **AND** the large widget displays palette B correctly
- **AND** changing palette A's small widget assignment does not affect the large widget

### Requirement: Widget configuration confirmation
After setting a palette as a widget, a brief confirmation SHALL appear in the app.

#### Scenario: Widget set confirmation
- **WHEN** user successfully sets a palette for the large widget
- **THEN** a toast/alert appears: "Set as Large Widget ✓"

### Requirement: Widget refresh on palette update
When a palette that is displayed by a widget is updated (e.g., colors or name changed), all widget timelines SHALL refresh to reflect the latest data.

#### Scenario: Update palette used in widget
- **WHEN** user renames a palette that is currently set as the large widget
- **AND** saves the palette
- **THEN** `WidgetCenter.shared.reloadAllTimelines()` is called
- **AND** the large widget updates to show the new palette name
