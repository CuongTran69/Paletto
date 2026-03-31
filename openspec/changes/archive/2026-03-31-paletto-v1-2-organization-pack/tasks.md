# Paletto v1.2 Organization Pack — Implementation Tasks

## 1. Foundation: Model & Migration

- [x] 1.1 Add `tags: [String] = []` field to `ColorPalette.swift` with `decodeIfPresent` defaulting to `[]`, add to `CodingKeys`, bump `version` default to `2`
- [x] 1.2 Add `migrateToV2()` case to `PaletteMigration.swift`: when `palette.version < 2`, set `tags = []` and `version = 2`, write back ← (verify: existing v1.1 palette loads and migrates correctly, version becomes 2, tags is empty array)
- [x] 1.3 Add `WidgetKind` enum (`case small, medium, large`) and `WidgetConfig` struct to `Constants.swift` or `SharedDataService.swift`
- [x] 1.4 Add limit constants to `Constants.swift`: `maxTagsPerPalette = 20`, `maxTagLength = 50`, `maxFolderNameLength = 100`, `maxFolderCount = 50`

## 2. Foundation: Localization

- [x] 2.1 Add ~25 new `L10n` keys to `LocalizationKeys.swift`: library.tag.*, library.folder.*, library.undo.*, widget.size.*, widget.configure.* ← (verify: all new keys reference existing key pattern, no typos)
- [x] 2.2 Add ~25 new string entries to `en.json` (matching new L10n keys)
- [x] 2.3 Add ~25 new string entries to `vi.json` (matching structure of en.json, Vietnamese translations)
- [x] 2.4 Verify en.json and vi.json are valid JSON after edits ← (verify: JSON parses without errors)

## 3. Feature: Folders — Model & Storage

- [x] 3.1 Create `Folder.swift` in `Core/Models/`: `struct Folder: Codable, Identifiable` with `id`, `name`, `paletteIds`, `createdAt`, `updatedAt` fields ← (verify: Codable round-trip test)
- [x] 3.2 Create `FolderStorageServiceProtocol.swift` in `Core/Services/Protocols/`: `loadFolders()`, `saveFolder(_:)`, `deleteFolder(id:)`, `updateFolder(_:)`
- [x] 3.3 Create `FolderStorageService.swift` in `Core/Services/`: implements protocol, persists `folders.json` to Application Support using serial `DispatchQueue`, matching `PaletteStorageService` pattern ← (verify: folder created, renamed, deleted persists after app restart)
- [x] 3.4 Extend `PaletteStorageServiceProtocol` in `Core/Services/Protocols/`: add `loadFolders()`, `saveFolder(_:)`, `deleteFolder(id:)`, `updateFolder(_:)` (delegates to FolderStorageService)
- [x] 3.5 Implement folder methods in `PaletteStorageService.swift`: delegates to `FolderStorageService.shared`
- [x] 3.6 Add `PaletteMigration` migration: if `folders.json` missing/corrupted, initialize empty array (no crash) ← (verify: corrupted/missing folders.json results in empty folder list, no crash)

## 4. Feature: Tags — Library Filtering

- [x] 4.1 Add to `PaletteListViewModel`: `@Published var folders: [Folder] = []`, `@Published var selectedFolder: Folder?`, `@Published var selectedTag: String?`, `@Published var allTags: [String] = []`
- [x] 4.2 Update `PaletteListViewModel.filteredPalettes`: combine search text + selectedTag + selectedFolder filtering ← (verify: tag filter + search both active returns intersection)
- [x] 4.3 Update `PaletteListViewModel.loadPalettes()`: load folders alongside palettes, compute `allTags` from all palette tags
- [x] 4.4 Add `PaletteListViewModel.loadFolders()`, `createFolder(name:)`, `renameFolder(id:, name:)`, `deleteFolder(id:)`, `addPaletteToFolder(paletteId:, folderId?)` methods
- [x] 4.5 Add `PaletteListViewModel.addTagToPalette(paletteId:, tag:)`, `removeTagFromPalette(paletteId:, tag:)` methods
- [x] 4.6 Create `TagFilterBar.swift` component: horizontal `ScrollView` of `HStack` chips — "All" + one per `allTags` + "+ New Tag" chip, selected chip highlighted with brand gradient ← (verify: VoiceOver reads each chip with name and count)
- [x] 4.7 Create `NewTagInlineField` in `TagFilterBar.swift`: inline text field replacing "+ New Tag" chip on tap, "Add" button, "Cancel" button, validation (max 50 chars, no "/", no empty) ← (verify: empty/whitespace input rejected, "/" character rejected with error)
- [x] 4.8 Create `FolderSection.swift` component: collapsible section header "My Folders" with chevron, list of `FolderRowView` (folder icon + name + palette count), "+ New Folder" row
- [x] 4.9 Create `FolderRowView.swift`: folder name, count badge, tappable → navigate to folder-filtered list, context menu with Rename/Delete ← (verify: long-press shows context menu)
- [x] 4.10 Update `PaletteListView.swift`: integrate `TagFilterBar` above palette list, integrate `FolderSection` above "All Palettes", add folder detail view (filtered list + back button)
- [x] 4.11 Add folder creation sheet/alert to `PaletteListView`: name input, create/cancel buttons ← (verify: folder created appears immediately in section)
- [x] 4.12 Update `PaletteRowView` in `PaletteListView.swift`: show compact tag chips below color strip when `palette.tags.isEmpty == false`

## 5. Feature: Tags — Palette Detail

- [x] 5.1 Update `PaletteDetailViewModel`: add `@Published var showTagEditor = false`, `@Published var newTagText = ""`
- [x] 5.2 Add `PaletteDetailViewModel.addTag(_:)`, `removeTag(_:)`, `addTagToCurrentPalette(tag:)` methods
- [x] 5.3 Create `TagEditorSection` in `PaletteDetailView.swift`: horizontal chip strip showing current palette tags with "×" remove buttons, "+ Add Tag" button opening inline text field ← (verify: add tag updates palette.tags, saves to storage, shows immediately)
- [x] 5.4 Add tag validation to `PaletteDetailViewModel`: max 20 tags, max 50 chars, no "/", no duplicates, no empty ← (verify: exceeding limits shows inline error, tag not added)
- [x] 5.5 Update `PaletteListViewModel.addTagToPalette`: refresh `allTags` after adding tag ← (verify: new tag appears in filter bar immediately)

## 6. Feature: Undo/Redo — Core

- [x] 6.1 Update `PalettoApp.swift`: add `.isUndoEnabled(true)` to `WindowGroup` ← (verify: UndoManager accessible via @Environment in all views)
- [x] 6.2 Create `UndoManager+Helpers.swift` utility: `performUndoGroup(_ label: String, _ action: () -> Void)` wrapper that calls `undoManager?.registerUndo(withTarget:)` with label

## 7. Feature: Undo/Redo — Palette Detail

- [x] 7.1 Update `PaletteDetailViewModel`: add `@Environment(\.undoManager) var undoManager: UndoManager?`, wrap `updateRole` in `withUndoGroup("Change Role")` ← (verify: undo reverts role, redo reapplies)
- [x] 7.2 Wrap `updateName` in `withUndoGroup("Edit Name")` in `PaletteDetailViewModel`
- [x] 7.3 Wrap `autoAssignRoles` in `withUndoGroup("Auto Assign Roles")` in `PaletteDetailViewModel`
- [x] 7.4 Wrap `applyFix` in `withUndoGroup("Fix Contrast")` in `PaletteDetailViewModel`
- [x] 7.5 Update `PaletteDetailView.swift`: add Undo and Redo `ToolbarItem`s on the leading side of navigation bar (left side of back button) ← (verify: buttons visible in toolbar, disabled when no history)
- [x] 7.6 Connect Undo/Redo toolbar buttons: `Button { undoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward") }` with `disabled(undoManager?.canUndo != true)` ← (verify: button disabled when canUndo is false)
- [x] 7.7 Add haptic feedback on undo/redo tap when `hapticFeedbackEnabled == true`

## 8. Feature: Undo/Redo — Palette Extraction

- [x] 8.1 Update `PaletteExtractionViewModel`: add `@Environment(\.undoManager) var undoManager: UndoManager?`
- [x] 8.2 Wrap `addPickedColor()` in `PaletteExtractionViewModel` with undo group labeled "Add Color" ← (verify: undo removes added color, redo adds it back)
- [x] 8.3 Wrap `removeColor(at:)` in `PaletteExtractionViewModel` with undo group labeled "Remove Color" ← (verify: undo restores removed color)
- [x] 8.4 Wrap `moveColor(from:to:)` in `PaletteExtractionViewModel` with undo group labeled "Reorder Colors"
- [x] 8.5 Update `PaletteExtractionView.swift`: add Undo button below palette strip (visible when `extractedColors.isEmpty == false`) ← (verify: button disabled when no undo history)
- [x] 8.6 Add haptic feedback on undo tap in `PaletteExtractionView`

## 9. Feature: Widget — Shared Data

- [x] 9.1 Update `SharedDataService.swift`: replace `setWidgetPalette(_:)` with `setWidgetPalette(_ palette: ColorPalette, forKind kind: WidgetKind)` and `setWidgetPalettes([WidgetPalette])` ← (verify: each size slot stores independent palette)
- [x] 9.2 Update `SharedDataService.swift`: replace `getWidgetPalette()` with `getWidgetPalette(forKind kind: WidgetKind) -> WidgetPalette?` reading from correct `UserDefaults[widget_{kind.rawValue}]` key
- [x] 9.3 Update `SharedDataService.getWidgetPalette()` calls in `PaletteTimelineProvider` to pass `kind` based on `family` parameter ← (verify: small widget reads `widget_small`, medium reads `widget_medium`, large reads `widget_large`)
- [x] 9.4 Update `PaletteTimelineProvider.getTimeline`: read `WidgetConfig` from correct key, extract `palette` field ← (verify: empty slot shows empty state)

## 10. Feature: Widget — Large Size UI

- [x] 10.1 Update `PalettoWidgetBundle.swift`: add `.systemLarge` to `supportedFamilies` array ← (verify: large widget available in widget gallery)
- [x] 10.2 Update `PalettoWidgetEntryView.swift`: add `largeWidget(_:)` method with layout: palette name at top, up to 8 horizontal color swatches (color fill + hex label + role label below each), "Paletto · Tap to open" footer ← (verify: large widget renders correctly with 3/5/8 colors, shows empty slots for fewer colors)
- [x] 10.3 Update `PalettoWidgetEntryView.body`: add `.systemLarge` case to switch statement ← (verify: large widget displays largeWidget layout, not smallWidget fallback)
- [x] 10.4 Add accessibility labels to each swatch in large widget: hex value + role name ← (verify: VoiceOver announces swatch info correctly)

## 11. Feature: Widget — Multi-Size Menu & AppIntent

- [x] 11.1 Create `SelectWidgetPaletteIntent.swift` in `AppIntents/` or `Paletto/` directory using AppIntents framework: `AppEntity` for `ColorPalette` (provides palette name and hex list), `AppIntent` with `parameter: selectedPalette` ← (verify: iOS 17+ widget Edit Widget shows palette picker)
- [x] 11.2 Gate `SelectWidgetPaletteIntent` with `if #available(iOS 17.0, *)` ← (verify: iOS 16 build does not crash on AppIntent reference)
- [x] 11.3 Update `PaletteDetailViewModel`: add `setAsWidget(forKind: WidgetKind)` method that calls `SharedDataService.shared.setWidgetPalette(palette, forKind: kind)` and triggers `WidgetCenter.shared.reloadTimelines(ofKind:)`
- [x] 11.4 Update `PaletteDetailView` toolbar "Set as Widget" menu: replace single action with `Menu` containing three `Button`s: "Small Widget", "Medium Widget", "Large Widget", each calling `setAsWidget(forKind:)` ← (verify: selecting "Large Widget" sets large slot, shows confirmation)
- [x] 11.5 Add widget confirmation alert: `"Set as {size} Widget"` when `showWidgetConfirmation` is true
- [x] 11.6 Add `reloadTimelines(ofKind:)` method to `SharedDataService`: calls `WidgetCenter.shared.reloadTimelines(ofKind: "PalettoWidget")`

## 12. Integration & Polish

- [x] 12.1 Update `PaletteListViewModel.loadPalettes()`: after loading palettes, refresh `allTags` and folders ← (verify: tags filter bar populated after load)
- [x] 12.2 Update `PaletteDetailViewModel.updateRole`, `updateName`, `applyFix`: call `WidgetCenter.shared.reloadAllTimelines()` after save ← (verify: widget updates when palette is edited)
- [x] 12.3 Update `PaletteDetailView`: add "Set as Widget" menu (multi-size) ← (verify: all three size options visible and functional)
- [x] 12.4 Add folder breadcrumb navigation in Library: when inside a folder, show "← Back to Library" ← (verify: navigation back works correctly)
- [x] 12.5 Test combined feature flow: create folder, add palette with tags, assign palette to folder, undo role change, set as large widget ← (verify: all features work together)
- [x] 12.6 Verify v1.1 palette file backward compatibility: save a palette in v1.2 (version 2 with tags), manually edit JSON to version 1, open app ← (verify: palette migrates gracefully, no crash, tags = [])
