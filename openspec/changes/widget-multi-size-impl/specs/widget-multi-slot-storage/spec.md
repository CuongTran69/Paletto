# Widget Multi-Slot Storage

## ADDED Requirements

### Requirement: Independent widget slots per size
The app SHALL store widget configuration in App Group UserDefaults with one entry per widget size (small, medium, large). Each entry holds the `WidgetPalette` data and an `updatedAt` timestamp. Slots are independent — setting a palette for one size does not affect other sizes.

#### Scenario: Set large widget palette
- **WHEN** user selects a palette for the large widget size
- **THEN** `UserDefaults[appGroup]["widget_large"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

#### Scenario: Set medium widget palette
- **WHEN** user selects a palette for the medium widget size
- **THEN** `UserDefaults[appGroup]["widget_medium"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

#### Scenario: Set small widget palette
- **WHEN** user selects a palette for the small widget size
- **THEN** `UserDefaults[appGroup]["widget_small"]` stores `WidgetConfig(palette: WidgetPalette, updatedAt: Date())`

#### Scenario: Slots are independent
- **WHEN** user sets palette A for the small widget
- **AND** user sets palette B for the large widget
- **THEN** reading `widget_small` returns palette A
- **AND** reading `widget_large` returns palette B
- **AND** changing the small widget does not affect the large widget

### Requirement: Optional palette slot
A widget slot MAY be empty. When a slot contains no data, `WidgetConfig.palette` SHALL be `nil` and the widget SHALL display the empty state for that size.

#### Scenario: Empty slot shows empty state
- **WHEN** `UserDefaults[appGroup]["widget_large"]` contains no data
- **THEN** the large widget shows "Set a palette in Paletto" empty state

#### Scenario: Partial slot configuration
- **WHEN** user sets only the large widget palette (small and medium are empty)
- **THEN** small widget shows empty state
- **AND** medium widget shows empty state
- **AND** large widget shows the configured palette

### Requirement: Palette includes color roles
`WidgetPalette` SHALL carry an array of role strings parallel to `hexColors`, allowing the widget to display role labels.

#### Scenario: Palette with assigned roles
- **WHEN** a palette has colors with roles: Color 0 = Background, Color 1 = Primary, Color 2 = nil
- **THEN** `WidgetPalette.roles` = `["Background", "Primary", ""]`

#### Scenario: Palette with no roles assigned
- **WHEN** a palette has colors with no roles assigned
- **THEN** `WidgetPalette.roles` = `["", "", ""]` (empty strings matching color count)

### Requirement: Widget slot reload
When a palette is set for a widget slot, the widget SHALL refresh to reflect the change immediately.

#### Scenario: Reload after setting widget palette
- **WHEN** user sets a palette for the large widget
- **THEN** `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")` is called
- **AND** the large widget updates within seconds to show the new palette

### Requirement: Reload on palette edit
When a palette that is displayed by any widget is updated, all widget timelines SHALL refresh.

#### Scenario: Edit palette used in widget
- **WHEN** user renames a palette that is currently set as a widget
- **AND** saves the palette
- **THEN** `WidgetCenter.shared.reloadAllTimelines()` is called
- **AND** the widget updates to show the new palette name
