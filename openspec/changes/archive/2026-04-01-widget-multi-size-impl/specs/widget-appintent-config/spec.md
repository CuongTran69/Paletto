# Widget AppIntent Configuration

## ADDED Requirements

### Requirement: AppIntent widget configuration (iOS 17+)
The app SHALL provide a `SelectWidgetPaletteIntent` AppIntent that allows users to select a palette for each widget size directly from the iOS widget configuration UI (long-press → Edit Widget).

#### Scenario: Configure widget via AppIntent on iOS 17+
- **WHEN** user long-presses the Paletto widget and taps "Edit Widget" on iOS 17+
- **THEN** the widget configuration UI shows a palette picker listing all saved palettes
- **AND** user selects a palette
- **AND** user selects a widget size (Small / Medium / Large)
- **THEN** the selected palette is written to the appropriate widget slot
- **AND** `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")` is called
- **AND** the widget refreshes to show the selected palette

#### Scenario: AppIntent on iOS 16
- **WHEN** user runs on iOS 16 and long-presses the Paletto widget
- **THEN** the widget configuration UI shows the default placeholder (no custom AppIntent picker)
- **AND** user uses the in-app "Set as Widget" menu instead

### Requirement: Palette picker displays palette name and color count
The `ColorPaletteEntity` displayed in the widget configuration picker SHALL show the palette name and color count as its representation string.

#### Scenario: Palette picker shows correct names
- **WHEN** user opens the widget palette picker
- **THEN** the list shows each palette's name (e.g., "Spring Colors — 5 colors")
- **AND** the entities are sorted alphabetically by name

### Requirement: Widget size picker
The widget configuration UI SHALL provide a widget size selector (Small / Medium / Large) alongside the palette picker.

#### Scenario: Widget size picker
- **WHEN** user is in the Edit Widget configuration
- **THEN** there is a "Widget Size" parameter with options: Small, Medium, Large
- **AND** selecting a size writes to the corresponding widget slot

### Requirement: AppIntent gated for iOS version
`SelectWidgetPaletteIntent` SHALL be gated with `if #available(iOS 17.0, *)` to prevent crashes on iOS 16.

#### Scenario: iOS 16 build does not crash
- **WHEN** the app is built for iOS 16
- **THEN** `SelectWidgetPaletteIntent` is not referenced at runtime
- **AND** no crash occurs

### Requirement: StaticConfiguration fallback (iOS 16)
On iOS 16, the widget SHALL use `StaticConfiguration` with `PaletteTimelineProvider` that reads the correct slot via family→kind mapping.

#### Scenario: iOS 16 widget reads correct slot
- **WHEN** a user on iOS 16 adds a large widget
- **AND** sets a palette via the in-app "Set as Widget" menu
- **THEN** the widget displays that palette correctly
- **AND** the timeline reads from `widget_large` UserDefaults key
