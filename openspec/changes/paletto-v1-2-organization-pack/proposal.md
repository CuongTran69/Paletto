## Why

Paletto v1.1 launched successfully to the App Store with core color extraction, camera picking, library management, and sharing features. As users accumulate more palettes, the flat library list becomes unwieldy — there's no way to organize, group, or quickly find palettes by project or theme. Simultaneously, editing actions (changing color roles, fixing contrast) lack undo support, making edits feel risky. Finally, the widget — supporting only small and medium sizes with a single palette — underutilizes iOS widget capabilities. These three gaps directly impact daily-use quality.

## What Changes

- **Tags**: Each palette gains an optional `tags: [String]` field. Users can label palettes (e.g., "nature", "brand", "app-ui"). Tags are multi-value — one palette can have zero or more tags. Tags are stored as a **breaking model change** in `ColorPalette` (`version` bumps 1 → 2) with a migration step.

- **Folders**: Folders are top-level organizational containers, stored in a separate `Folders.json` file (non-breaking to palette files). Each folder has a name, creation date, and list of palette IDs. Palettes reference folders by ID. Users can create, rename, and delete folders; deleting a folder leaves palettes intact (uncategorized).

- **Tag Filter Bar**: A horizontal chip-based filter bar appears above the palette list in the Library tab. Chips include "All" and one per unique tag. Tapping a chip filters the list. A "+ New Tag" chip opens an inline text field.

- **Folder Sections**: The Library tab groups palettes under collapsible "My Folders" section(s) above the flat "All Palettes" list.

- **Undo/Redo**: SwiftUI's `UndoManager` is enabled in `PalettoApp`. Undo groups wrap state-changing operations in `PaletteDetailViewModel` (role updates, name edits, contrast fixes) and `PaletteExtractionViewModel` (color add/remove/reorder). Undo/Redo buttons appear in each screen's toolbar.

- **Large Widget**: The widget gains `.systemLarge` size. Large widget shows the palette name, all colors as labeled swatches (up to 8), and "Paletto · Tap to open" footer. Existing small and medium layouts are preserved unchanged.

- **Multiple Widget Palettes**: `SharedDataService` supports storing N palettes (array) mapped to widget sizes (small/medium/large). The "Set as Widget" menu in Palette Detail lets users pick which widget size to update. A new AppIntent (`SelectWidgetPaletteIntent`, iOS 17+) provides configurable widget support via long-press → Edit Widget.

## Capabilities

### New Capabilities

- `palette-tags`: Assign, add, remove, and filter by multiple string tags on any saved palette. Tags are stored in the palette model and persist via the existing storage service. Tag filter bar in Library enables quick filtering.
- `palette-folders`: Create, rename, and delete organizational folders. Assign palettes to folders. Folders stored in `Folders.json` alongside palette files. Collapsible folder sections in Library.
- `palette-undo-redo`: Undo and redo state-changing operations in Palette Detail and Palette Extraction screens using SwiftUI's UndoManager. Toolbar buttons for both directions, disabled when history is empty.
- `widget-large-size`: New `.systemLarge` widget layout for Home Screen. Full color swatch strip with hex labels and palette name. Integrated with existing widget data pipeline.
- `widget-multiple-palettes`: Store multiple palettes in App Group UserDefaults (one per widget size). "Set as Widget" action sheet lets user pick size. iOS 17+ AppIntent provides home-screen widget configuration.

### Modified Capabilities

- `palette-storage`: The storage service is extended to handle folder CRUD operations (separate file) and tag field on palette load/save. Palette migration path from v1 (no tags) to v2 (tags array) is required.
- `widget-deep-link-navigation`: No requirement change — widget deep links continue to open the palette detail view via existing URL scheme.

## Impact

- **Model**: `ColorPalette.tags` added (breaking, version 1→2), `PaletteMigration` updated
- **Storage**: New `Folders.json` file; `PaletteStorageService` extended; `PaletteStorageServiceProtocol` extended
- **Widget Target**: New `.systemLarge` family in `PalettoWidgetBundle`; `SharedDataService` updated for array of N palettes mapped to sizes
- **App Target**: New `Folder.swift` model; new `FolderStorageService`; UI changes in `PaletteListView`, `PaletteDetailView`, `PaletteExtractionView`; ViewModel changes in all three; `PalettoApp.swift` enables undo
- **Intents Target**: New `SelectWidgetPaletteIntent` using AppIntents framework (iOS 17+)
- **Localization**: ~50 new keys in en.json and vi.json for folder/tag/undo/widget strings
- **Dependencies**: None — all work is within the existing codebase; AppIntents is a system framework
