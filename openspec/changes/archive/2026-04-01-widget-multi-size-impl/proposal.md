# Widget Multi-Size Implementation — Proposal

## Why

The existing Paletto widget extension supports only `.systemSmall` and `.systemMedium` sizes with a single shared palette slot. Users cannot configure which palette each widget size displays, cannot add the `.systemLarge` widget to their Home Screen, and cannot pick a palette directly from the iOS widget configuration UI. This limits the widget's utility as a daily-use organizational tool.

## What Changes

- **Multi-slot widget data model**: Replace the single `widgetPalette` UserDefaults key with three independent slots (`widget_small`, `widget_medium`, `widget_large`), each storing a `WidgetConfig` with its own palette and timestamp.
- **`.systemLarge` widget support**: Add `systemLarge` to `supportedFamilies`, create a `largeWidget()` layout in `PalettoWidgetEntryView`, and wire the timeline provider to read the correct slot based on widget family.
- **In-app "Set as Widget" menu**: The palette detail toolbar already has a multi-size Menu. Wire it to write to the correct slot and trigger a targeted widget reload.
- **AppIntent widget configuration (iOS 17+)**: Implement `SelectWidgetPaletteIntent` so users can pick a palette directly from the iOS Edit Widget UI.
- **Color role labels in large widget**: Carry color role data through to the widget so large widget swatches display hex + role label.

## Capabilities

### New Capabilities

- `widget-multi-slot-storage`: Independent UserDefaults slots per widget size (small/medium/large), each holding `WidgetConfig(palette: WidgetPalette?, updatedAt: Date)`.
- `widget-large-size`: Full `.systemLarge` widget layout — palette name, up to 8 labeled color swatches, footer — with independent slot management.
- `widget-appintent-config`: `SelectWidgetPaletteIntent` AppIntent for iOS 17+ widget configuration picker.

### Modified Capabilities

- `widget-deep-link-navigation`: No requirement changes. Implementation updates to read from the correct per-size slot.

## Impact

- **Files modified**: `SharedDataService.swift` (add `setWidgetPalette(_:, forKind:)` / `getWidgetPalette(forKind:)`), `PalettoWidget.swift` (family→kind mapping), `PalettoWidgetEntryView.swift` (add `largeWidget()`), `PalettoWidgetBundle.swift` (add `.systemLarge`), `PaletteDetailViewModel.swift` (wiring), `Constants.swift` (fix `WidgetConfig.palette` to optional).
- **Files created**: `SelectWidgetPaletteIntent.swift` (AppIntent, iOS 17+).
- **Dependencies**: AppIntents framework (iOS 16+, stable iOS 17+), WidgetKit, App Group UserDefaults.
- **Break**: `WidgetConfig.palette` must change from non-optional to optional. Existing widget data stored under `widgetPalette` key is abandoned (no migration needed — the old key is not referenced in new code).
