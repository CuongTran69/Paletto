## Context

Paletto v1.1 is a native SwiftUI iOS app (iOS 16.0+) that extracts color palettes from photos and the camera. It supports 4 tabs (Extract, Camera, Library, Settings) with a widget extension. Core models are `ColorPalette` and `PaletteColor` persisted as JSON files. The widget displays a single palette via App Group UserDefaults.

Three issues limit daily-use quality as palette counts grow:
1. **Flat library** — no organizational structure; finding palettes becomes tedious
2. **No undo** — editing roles, names, or contrast feels permanent and risky
3. **Limited widget** — only 2 sizes, 1 palette, no user configuration

Existing architecture follows a service-protocol-VM-view pattern with protocol-oriented dependency injection. Storage is file-based (JSON per palette). Localization uses JSON files per language.

**Constraints:**
- iOS 16.0 minimum deployment target
- Widget extension is a separate target with no access to the main app's code
- Widget currently shares data via App Group UserDefaults only
- No existing test suite

## Goals / Non-Goals

**Goals:**
- Enable multi-tag labeling of palettes with tag-based filtering in the library
- Provide folder-based palette organization with collapsible sections
- Add full undo/redo to palette editing and extraction screens
- Extend widget to 3 sizes (small/medium/large) with configurable palette per size
- Maintain backward compatibility with v1.1 palette files

**Non-Goals:**
- Cloud sync or cross-device support (iCloud planned for a future version)
- Social features (sharing palettes to a community feed)
- iPad-specific layouts or macOS support
- Changing the core color extraction or harmony generation algorithms
- Multi-user support

## Decisions

### D1: Tags as array in `ColorPalette` (breaking model change)

**Decision:** Add `tags: [String] = []` directly to the `ColorPalette` struct and bump `version` from 1 to 2.

**Rationale:** Tags are intrinsically tied to the palette — they travel with the palette through sharing, export, and storage. Storing them on the model is the natural ownership model. The alternative (separate tags file keyed by palette ID) creates a two-phase load problem: what if a palette exists but its tag record is missing?

**Alternative considered:** Separate `PaletteTags.json` (paletteId → [String]) — rejected because it creates orphaned tag data when palettes are deleted and requires two-file consistency on every load.

**Migration:** `PaletteMigration.migrateIfNeeded()` checks `palette.version < 2`, sets `tags = []`, writes back with `version = 2`. Runs lazily on first load.

### D2: Folders in separate `Folders.json` (non-breaking)

**Decision:** Folders are stored in a single `folders.json` file in the Application Support directory, alongside individual palette JSON files. Each folder holds an array of palette UUIDs.

**Rationale:** Folders are a collection view over palettes, not a property of a palette. Keeping them in a separate file avoids any breaking change to palette files and makes folder operations atomic (create/delete/rename don't touch palette files at all). A palette's folder membership is a reference, not ownership.

**Alternative considered:** Add `folderId: UUID?` field to `ColorPalette` — rejected because it makes moving a palette between folders require updating the palette file (not atomic), and a palette can't logically belong to multiple folders.

**Schema:**
```swift
struct Folder: Codable, Identifiable {
    let id: UUID
    var name: String
    var paletteIds: [UUID]
    let createdAt: Date
    var updatedAt: Date
}
```

### D3: Folders are NOT tags

**Decision:** Folders and tags serve different purposes. Folders are exclusive containers (a palette is in exactly one folder or uncategorized). Tags are non-exclusive labels (a palette can have zero or many tags). Both coexist.

**Rationale:** This is the standard "folder + label" model (similar to Gmail, file systems). Folders provide structural organization; tags provide flexible cross-cutting categorization. Conflating them creates UX confusion.

### D4: Undo via SwiftUI `@Environment(\.undoManager)`

**Decision:** Enable `isUndoEnabled = true` on the `WindowGroup` in `PalettoApp.swift`, then inject `UndoManager` via `@Environment` into view models and views.

**Rationale:** Native, zero-dependency, system-integrated. The undo group API (`withUndoGroup { }`) wraps state changes cleanly. Undo/redo buttons can be bound directly to `undoManager?.undo()` / `redo()` calls. The system handles coalescing, registration limits, and menu integration automatically.

**Scope:** `PaletteDetailViewModel` (role changes, name edits, contrast fixes) and `PaletteExtractionViewModel` (color add/remove/reorder). Library-level operations (delete palette) are **not** wrapped in undo — deleting from disk is a destructive operation that requires explicit confirmation.

**Alternative considered:** Custom command stack — rejected because it duplicates UndoManager's functionality without any benefit.

### D5: Widget data model — array of `WidgetPalette` in UserDefaults

**Decision:** Replace the single `WidgetPalette` in UserDefaults with `[WidgetPalette]` (array). Each element in the array maps to a widget size slot (small, medium, large) via `WidgetKind` enum.

**Rationale:** The simplest extension that supports multiple widget sizes. `WidgetKind` enum maps directly to `WidgetFamily` values. The app writes the selected palette to the slot matching the user's chosen size.

**Storage schema:**
```swift
enum WidgetKind: String, Codable {
    case small, medium, large
}

struct WidgetConfig: Codable {
    let palette: WidgetPalette?
    let updatedAt: Date
}

UserDefaults[appGroup]["widget_\(kind.rawValue)"] = WidgetConfig
```

### D6: Large widget — Option B: palette detail panel

**Decision:** Large widget shows palette name, all colors as labeled swatches (up to 8), and "Paletto · Tap to open" footer. Colors without hex labels are shown as swatches only.

**Rationale:** Maximizes the larger screen real estate by showing the maximum useful color information. Hex labels help developers copy colors directly. Footer provides clear tap affordance.

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│  [Palette Name — up to 2 lines]                         │
│  ───────────────────────────────────────────────────    │
│  [Color 1 swatch]  [Color 2 swatch]  ... up to 8       │
│  (hex label below each, role label if assigned)         │
│                                                         │
│  Paletto · Tap to open                                  │
└─────────────────────────────────────────────────────────┘
```

### D7: Widget configuration — AppIntent (iOS 17+) with menu fallback (iOS 16)

**Decision:** Implement `SelectWidgetPaletteIntent` using the AppIntents framework (available from iOS 16, stable from iOS 17) for widget configuration. On iOS 16, the "Set as Widget" action sheet in Palette Detail provides size selection.

**Rationale:** AppIntent-based widget configuration requires iOS 17 for full stability, especially with `AppEntity` and `DynamicOptions`. iOS 16 users still get the in-app "Set as Widget" menu, which writes directly to UserDefaults. This provides feature parity for both OS versions.

**iOS 16 fallback:** "Set as Widget" action sheet (existing pattern in app) lets user pick small/medium/large. Widget refreshes via `reloadTimelines(ofKind:)`.

### D8: App Group identifier

**Decision:** Use existing `group.com.paletto.shared` (already configured). No changes needed.

### D9: Localization strategy

**Decision:** Add all new strings to existing `en.json` and `vi.json` files using nested JSON structure matching the existing pattern. `LocalizationKeys.swift` gets corresponding `static let` entries. No new localization file format.

**Rationale:** Maintains consistency with v1.1 pattern. Adding to existing files is non-breaking.

## Risks / Trade-offs

**[Risk: PaletteMigration version bump could break if `version` field is missing from older files]** → **Mitigation:** `PaletteMigration.migrateIfNeeded` checks `palette.version` with `decodeIfPresent` (defaults to 1 if missing). New tag field uses `decodeIfPresent` with empty array default. Verified: decoder already handles missing fields gracefully.

**[Risk: Folder deletion with palette references]** → **Mitigation:** When a folder is deleted, its `paletteIds` are simply abandoned (palettes lose folder membership, not deleted). Confirmation alert warns user before folder deletion. No cascade delete.

**[Risk: Tag name collisions (duplicate tags)]** → **Mitigation:** Tags are stored as strings on the palette model — no canonical tag list. The "All Tags" in the filter bar is computed dynamically from all palette tags. Adding a tag to a palette that already has that tag is a no-op.

**[Risk: UndoManager memory pressure with large histories]** → **Mitigation:** SwiftUI's UndoManager has built-in registration limits (typically 20–40 groups). Palette editing operations are small (color arrays, string edits) so memory impact is negligible.

**[Risk: Widget AppIntent not available before iOS 17]** → **Mitigation:** iOS 16 users use the in-app "Set as Widget" action sheet. The AppIntent is gated with `if #available(iOS 17.0, *)`.

**[Risk: Breaking ColorPalette model changes could affect widget decoding]** → **Mitigation:** Widget uses `WidgetPalette` (separate lightweight struct) and `WidgetPaletteData` (widget target's own copy). Neither references `ColorPalette` directly. No coupling risk.

**[Risk: Concurrent access to Folders.json]** → **Mitigation:** `FolderStorageService` uses `DispatchQueue` (serial queue) for all file operations, matching the pattern used by `PaletteStorageService`.

**[Risk: Tag names with "/" or "#" characters could break URL encoding in sharing]** → **Mitigation:** Tags with "/" are rejected with "Tags cannot contain '/'". Sanitization applied before storage.

## Migration Plan

**Deploy sequence:**
1. Ship v1.2 with model version 2, migration code, and all new features
2. On first launch of v1.2, `loadAll()` calls `PaletteMigration.migrateIfNeeded` lazily per palette
3. Migration runs synchronously in the background (no UI blocking) on first load
4. v1.1 palette files remain valid — migration adds `tags: []` without breaking reads

**Rollback:** If v1.2 has a critical bug, v1.1 APK can be re-submitted. Palette files with `version: 2` and `tags: []` are readable by v1.1 (v1.1 decoder uses `decodeIfPresent` for unknown fields). v1.2-specific features (folders, undo) simply won't function in v1.1.

**No forward migration path needed** — v1.2 writes files with `version: 2`. Future v1.3 migration will check `version < 3`.

## Open Questions

- **Q1: Maximum number of tags per palette?** Limit to 20 tags per palette. Reasonable UX for any real-world scenario. (→ DECIDED: 20)
- **Q2: Maximum tag name length?** Limit to 50 characters. (→ DECIDED: 50)
- **Q3: Maximum folder name length?** Limit to 100 characters. (→ DECIDED: 100)
- **Q4: Maximum number of folders?** Limit to 50 folders per user. (→ DECIDED: 50)
- **Q5: Should the "All" tag filter show uncategorized palettes (no tags) or all palettes?** Show all palettes — "All" means all palettes regardless of tags. (→ DECIDED)
- **Q6: Widget large with fewer than 8 colors?** Show available colors, leave remaining swatch slots empty. (→ DECIDED)
