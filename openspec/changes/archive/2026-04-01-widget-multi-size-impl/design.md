# Widget Multi-Size Implementation — Design

## Context

Paletto v1.2 has `WidgetKind` enum and `WidgetConfig` struct already defined in `Constants.swift`, alongside a `widgetSlotKey(for:)` helper. The existing `SharedDataService` still uses a single `widgetPaletteKey` with a flat `WidgetPalette` struct. The widget extension's `PaletteTimelineProvider` reads from the single old key and renders only `.systemSmall` / `.systemMedium`. `PaletteDetailViewModel` already has `setAsWidget(forKind:)` but calls a non-existent `SharedDataService` method.

**Constraints:**
- iOS 16.0 minimum deployment target for the app; iOS 17+ for stable AppIntent widget configuration
- Widget extension is a separate target — cannot import main app code
- App Group identifier: `group.com.paletto.shared` (already configured)

## Goals / Non-Goals

**Goals:**
- Three independent widget size slots (small/medium/large), each storing its own palette
- `.systemLarge` widget available in gallery, renders palette name + up to 8 labeled swatches
- Timeline provider reads from the correct slot based on `WidgetFamily`
- iOS 17+ AppIntent widget configuration (palette picker from Edit Widget UI)
- Color role labels displayed on large widget swatches

**Non-Goals:**
- Supporting `.systemExtraLarge` or iPad widgets (iOS 17+ size classes not in scope)
- Cloud sync of widget configuration
- Multiple palettes per widget slot (one palette per slot)
- Configuring widget from outside the Paletto app on iOS 16 (in-app menu only)

## Decisions

### D1: `WidgetConfig.palette` must be optional

**Decision:** Change `WidgetConfig.palette` from `WidgetPalette` to `WidgetPalette?`.

**Rationale:** A widget slot can be empty — the user may add a large widget to their Home Screen without configuring a palette. When decoding `WidgetConfig` from UserDefaults, if `palette` is nil the widget should show the empty state. With a non-optional `palette`, JSON decoding would fail on empty slots.

### D2: `WidgetPalette` carries color role strings

**Decision:** Extend `WidgetPalette` (main app) with `roles: [String?]` and `WidgetPaletteData` (widget extension) with `colorRoles: [String?]` so the large widget can display role labels.

**Rationale:** The widget extension cannot access `ColorRole` enum or `ColorPalette` model. Role labels must be serialized as plain strings through the shared data layer. The `WidgetPalette` initializer in `SharedDataService` maps `palette.colors.map { $0.role?.rawValue }`.

### D3: `WidgetKind` defined in Constants.swift (shared) but used in both targets

**Decision:** Keep `WidgetKind` enum in `Constants.swift` (main app target). Define a duplicate `WidgetKind` enum in `PalettoWidget.swift` for the widget extension's use.

**Rationale:** The widget extension target cannot import Swift files from the main app target. The duplicate enum is identical in both targets (3 cases, `rawValue: String`, `Codable`). Both compile independently.

**Alternative considered:** Move `WidgetKind` to a shared framework target — rejected because it introduces a new build target and complexity disproportionate to a 3-case enum.

### D4: Timeline provider reads family → kind → UserDefaults key

**Decision:** `getTimeline(in:context:completion:)` in `PaletteTimelineProvider` maps `context.family` to a `WidgetKind` string, then calls `loadWidgetPalette(forKind:)`. The widget extension's `loadWidgetPalette(forKind:)` reads `UserDefaults[appGroup]["widget_\(kind.rawValue)"]` and decodes `WidgetConfigData` (a widget-local copy of `WidgetConfig`).

**Schema:**
```
// PalettoWidget.swift (widget extension, duplicates from Constants.swift)
enum WidgetKind: String, Codable, CaseIterable {
    case small, medium, large
}

struct WidgetConfigData: Codable {
    let palette: WidgetPaletteData?
    let updatedAt: Date
}

// UserDefaults[appGroup]["widget_small"]  = JSON(WidgetConfigData)
    UserDefaults[appGroup]["widget_medium"] = JSON(WidgetConfigData)
    UserDefaults[appGroup]["widget_large"] = JSON(WidgetConfigData)
```

### D5: Large widget layout

**Decision:** Large widget displays:
1. Palette name at top (up to 2 lines, truncated)
2. Horizontal color swatches in a 4×2 grid (up to 8 colors; fewer colors = fewer swatches with empty slots as transparent)
3. Each swatch: color fill + hex label below + role label below hex (if role exists)
4. Footer: "Paletto · Tap to open"

**Layout in code:**
```
VStack(spacing: 12) {
    Text(palette.name).font(.headline).lineLimit(2)
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
        ForEach(0..<8, id: \.self) { index in
            if index < palette.hexColors.count {
                VStack(spacing: 2) {
                    RoundedRectangle.fill(color)
                        .frame(height: 44)
                    Text(hex).font(.system(size: 8, design: .monospaced))
                    if let role = palette.colorRoles[safe: index] {
                        Text(role).font(.system(size: 7)).foregroundColor(.secondary)
                    }
                }
            } else {
                RoundedRectangle.fill(Color.clear)
                    .frame(height: 44)
                    .overlay(RoundedRectangle.strokeBorder(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
    }
    Text("Paletto · Tap to open").font(.caption2).foregroundColor(.secondary)
}
```

### D6: AppIntent widget configuration (iOS 17+)

**Decision:** Implement `SelectWidgetPaletteIntent` (AppIntent, `@available(iOS 17.0, *)`) with:
- `ColorPaletteEntity: AppEntity` — provides palette name + hex list as display representation
- `WidgetSizeEntity: AppEnum` — small / medium / large options
- `SelectWidgetPaletteIntent: AppIntent` — `selectedPalette` (ColorPaletteEntity) + `widgetSize` (WidgetSizeEntity) parameters
- `perform()` writes `WidgetConfigData` to the correct `widget_{size}` key and calls `WidgetCenter.shared.reloadTimelines(ofKind:)`

**Widget configuration:** `PalettoColorWidget` uses `AppIntentConfiguration` on iOS 17+ with `SelectWidgetPaletteIntent.self`, falling back to `StaticConfiguration` on iOS 16.

**iOS 16:** Users use the in-app "Set as Widget" menu (already implemented in `PaletteDetailView`).

### D7: Widget reload strategy

**Decision:**
- When user sets palette from in-app menu → `SharedDataService.setWidgetPalette(_:, forKind:)` saves data then calls `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")` (targets only the PalettoWidget kind)
- When palette is edited in `PaletteDetailViewModel` → `WidgetCenter.shared.reloadAllTimelines()` (updates all widget sizes that may display this palette)
- Timeline refresh policy remains 30 minutes (`.after(nextUpdate)`)

## Risks / Trade-offs

**[Risk: `WidgetConfig.palette` breaking change]** → Old widget data under `widgetPalette` key is orphaned. No migration needed — new code never reads the old key.

**[Risk: Widget reads wrong slot on iOS 16]** → `AppIntentConfiguration` requires iOS 17+. On iOS 16, `StaticConfiguration` reads the correct slot via family→kind mapping. Confirmed: both configurations share the same `PaletteTimelineProvider`.

**[Risk: Color roles not available for old palettes]** → `WidgetPalette.init(palette:)` maps `role?.rawValue ?? ""` — empty string for unassigned roles. Large widget only shows role label if the string is non-empty.

**[Risk: Large widget empty slots look broken]** → Empty swatch slots render with a dashed border (transparent fill with `strokeBorder`) to visually indicate "no color here" rather than appearing as invisible gaps.

## Migration Plan

**No migration needed.** The old `widgetPalette` UserDefaults key is abandoned. Existing palettes in storage are unaffected. New `widget_{kind}` keys are created on first write. No rollback risk.

**Deploy sequence:**
1. Ship with updated storage schema and new widget code
2. User adds large widget → gets empty state until palette is set
3. Existing small/medium widget instances continue to work (read their respective `widget_small` / `widget_medium` keys; if empty, show empty state)

## Open Questions

- **Q1: Should role labels be localized?** No — roles are stored as raw strings (e.g., "Background", "Primary") from `ColorRole.rawValue`. These are English by design (consistent with hex values). Localization not needed.
- **Q2: Widget placeholder / snapshot on iOS 17+?** The `placeholder(in:)` method returns a `PaletteEntry` with hardcoded palette data (unchanged from current). No slot-specific placeholder needed — the system handles snapshot display.
