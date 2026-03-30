# Widget Multi-Size Implementation — Tasks

## 1. Fix Data Model

- [x] 1.1 Update `WidgetConfig.palette` in `Constants.swift`: change `let palette: WidgetPalette` to `let palette: WidgetPalette?` ← (verify: WidgetConfig can now decode slots with nil palette)
- [x] 1.2 Update `WidgetPalette` in `SharedDataService.swift`: add `roles: [String?]` field and `Codable` conformance, update initializer `init(palette:)` to populate roles from `palette.colors.map { $0.role?.rawValue }`

## 2. Update SharedDataService (Core App)

- [x] 2.1 Replace `setWidgetPalette(_:)` with `setWidgetPalette(_ palette: ColorPalette, forKind kind: WidgetKind)` — encode `WidgetConfig(palette: WidgetPalette(palette), updatedAt: Date())` to `UserDefaults["widget_\(kind.rawValue)"]`, call `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")` ← (verify: calling `setWidgetPalette(p, forKind: .large)` writes to `widget_large` key)
- [x] 2.2 Replace `getWidgetPalette()` with `getWidgetPalette(forKind kind: WidgetKind) -> WidgetPalette?` — decode `WidgetConfig` from `UserDefaults["widget_\(kind.rawValue)"]`, return `config?.palette` ← (verify: empty slot returns nil, configured slot returns palette)

## 3. Update PaletteDetailViewModel Wiring

- [x] 3.1 Verify `setAsWidget(forKind:)` in `PaletteDetailViewModel` calls the new `SharedDataService.shared.setWidgetPalette(_:, forKind:)` method (already implemented, just ensure it compiles) ← (verify: method signature matches SharedDataService)
- [x] 3.2 Update `updateName`, `updateRole`, `applyFix` in `PaletteDetailViewModel`: ensure they call `WidgetCenter.shared.reloadAllTimelines()` after save (already present)

## 4. Add WidgetKind + WidgetConfigData to Widget Extension

- [x] 4.1 In `PalettoWidget.swift`: add duplicate `WidgetKind` enum (`case small, medium, large`, `rawValue: String`, `Codable`, `CaseIterable`) matching Constants.swift definition
- [x] 4.2 In `PalettoWidget.swift`: add `WidgetConfigData` struct (`Codable`, `let palette: WidgetPaletteData?`, `let updatedAt: Date`) — widget-local equivalent of `WidgetConfig`
- [x] 4.3 In `PalettoWidget.swift`: update `WidgetPaletteData` to add `colorRoles: [String?]` field (parallel to `WidgetPalette.roles` in main app) ← (verify: WidgetPaletteData has both `hexColors` and `colorRoles`)

## 5. Update Widget Timeline Provider

- [x] 5.1 Update `PaletteTimelineProvider.getTimeline(in:completion:)`: add `context.family` → `WidgetKind` mapping:
  ```
  let kind: WidgetKind
  switch context.family {
  case .systemSmall:  kind = .small
  case .systemMedium: kind = .medium
  case .systemLarge:  kind = .large
  default:            kind = .small
  }
  ```
- [x] 5.2 Replace `loadWidgetPalette()` with `loadWidgetPaletteData(forKind kind: WidgetKind) -> WidgetPaletteData?` — decode `WidgetConfigData` from `UserDefaults[appGroup]["widget_\(kind.rawValue)"]`, return `config?.palette` ← (verify: large widget reads `widget_large` key, small reads `widget_small`)
- [x] 5.3 Update `getTimeline`: pass `kind` to `loadWidgetPaletteData(forKind:)`, extract `.palette` for `PaletteEntry`
- [x] 5.4 Update `placeholder(in:)` in `PaletteTimelineProvider`: include `colorRoles` in the placeholder palette data

## 6. Add .systemLarge to Widget Bundle

- [x] 6.1 In `PalettoWidgetBundle.swift`: add `.systemLarge` to `supportedFamilies([.systemSmall, .systemMedium, .systemLarge])` ← (verify: large widget appears in widget gallery)

## 7. Add Large Widget Layout

- [x] 7.1 In `PalettoWidgetEntryView.swift`: add `largeWidget(_: WidgetPaletteData) -> some View` method with layout:
  - Palette name at top (`.font(.headline)`, `.lineLimit(2)`)
  - `LazyVGrid` with 4 columns (`GridItem(.flexible(), spacing: 6)`), `spacing: 8`
  - Loop 0..<8: if `index < palette.hexColors.count`, render swatch (color fill height 44, hex label font 8 monospaced, role label font 7 if `colorRoles[safe: index]` is non-empty); else render transparent dashed-border placeholder
  - Footer: `Text("Paletto · Tap to open").font(.caption2).foregroundColor(.secondary)`
  - `.widgetURL(URL(string: "paletto://palette/\(palette.id)"))`
  ← (verify: renders correctly with 3/5/8 colors, shows empty placeholder swatches)
- [x] 7.2 In `PalettoWidgetEntryView.body`: add `.systemLarge` case in the switch statement calling `largeWidget(palette)` ← (verify: large widget displays largeWidget layout, not fallback)
- [x] 7.3 Add `accessibilityLabel` to each swatch: `"Color \(hex), \(role ?? "no role") role"` ← (verify: VoiceOver announces swatch info correctly)

## 8. Create SelectWidgetPaletteIntent (AppIntent)

- [x] 8.1 Create `SelectWidgetPaletteIntent.swift` in `Paletto/AppIntents/` directory
- [x] 8.2 Add `import AppIntents` and wrap entire file in `if #available(iOS 17.0, *)`
- [x] 8.3 Define `ColorPaletteEntity: AppEntity`:
  - `var id: UUID`, `var name: String`, `var hexColorCount: Int`
  - `static var typeDisplayRepresentation`: `"Palette"`
  - `var displayRepresentation`: `DisplayRepresentation(title: "\(name) — \(hexColorCount) colors")`
  - `static var defaultQuery = PaletteQuery()`
  ← (verify: entity shows "Spring Colors — 5 colors" in picker)
- [x] 8.4 Define `PaletteQuery: EntityQuery`:
  - `func entities(for identifiers: [UUID]) async -> [ColorPaletteEntity]`: load palettes from storage, filter by identifiers, map to entity
  - `func suggestedEntities() async -> [ColorPaletteEntity]`: load all palettes, sort alphabetically, return all as entities
  - Conform to `Identifiable by UUID`
  ← (verify: picker lists all saved palettes alphabetically)
- [x] 8.5 Define `WidgetSizeEntity: AppEnum` with cases `.small, .medium, .large`, `typeDisplayName`: `"Widget Size"`, each case has `displayRepresentation`
- [x] 8.6 Define `SelectWidgetPaletteIntent: AppIntent`:
  - `static var title: LocalizedStringResource = "Select Palette"`
  - `static var description: IntentDescription? = "Choose a palette for your Paletto widget"`,
  - `@Parameter(title: "Palette") var selectedPalette: ColorPaletteEntity`
  - `@Parameter(title: "Widget Size") var widgetSize: WidgetSizeEntity`
  - `func perform() async throws -> some IntentResult`:
    - Load full `ColorPalette` from storage by `selectedPalette.id`
    - Build `WidgetPalette` with roles from colors
    - Write `WidgetConfigData(palette: WidgetPaletteData, updatedAt: Date())` to `UserDefaults["widget_\(widgetSize.rawValue)"]`
    - Call `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")`
  ← (verify: selecting palette + size from Edit Widget writes correct slot)

## 9. Wire AppIntent to Widget Configuration

- [x] 9.1 In `PalettoColorWidget` (PalettoWidgetBundle.swift): replace `StaticConfiguration` body with conditional:
  ```
  if #available(iOSApplicationExtension 17.0, *) {
      AppIntentConfiguration(kind: kind, intent: SelectWidgetPaletteIntent.self, provider: PaletteTimelineProvider()) { entry in
          PalettoWidgetEntryView(entry: entry)
              .containerBackground(.fill.tertiary, for: .widget)
      }
  } else {
      StaticConfiguration(kind: kind, provider: PaletteTimelineProvider()) { entry in
          PalettoWidgetEntryView(entry: entry)
              .padding()
              .background()
      }
  }
  ```
  ← (verify: iOS 17 Edit Widget shows AppIntent picker; iOS 16 uses StaticConfiguration)

## 10. Integration Test

- [ ] 10.1 Build app and widget extension — verify no compile errors ← (verify: both targets compile successfully)
- [ ] 10.2 Run on simulator: add small, medium, large widget instances, set different palettes for each via in-app menu ← (verify: each widget displays correct palette independently)
- [ ] 10.3 Test iOS 17+ AppIntent: long-press widget → Edit Widget → select palette → select size ← (verify: slot written, widget reloads)
- [ ] 10.4 Test large widget: 3/5/8 colors, role labels, empty slots, empty state ← (verify: all scenarios match spec)
- [ ] 10.5 Test VoiceOver on large widget swatches ← (verify: announces hex + role correctly)
