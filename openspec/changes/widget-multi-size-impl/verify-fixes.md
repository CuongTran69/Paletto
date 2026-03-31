## [2026-03-30] Round 1 (from spx-apply auto-verify)

### spx-verifier
- Fixed: Make `SharedDataService` decoder date strategy explicit — added `d.dateDecodingStrategy = .iso8601` to the decoder closure (previously relied on implicit default)

### spx-arch-verifier
- Fixed: **[CRITICAL]** `roles` key mismatch — renamed `WidgetPalette.roles` → `WidgetPalette.colorRoles` in `SharedDataService.swift`. Both targets now use snake_case key `"colorRoles"` in JSON, consistent with `WidgetPaletteData.colorRoles` in widget extension. `JSONEncoder` outputs `"colorRoles"` matching the Codable property name. Widget `JSONDecoder` decodes it correctly.
- Fixed: **[LOW]** Removed dead `Constants.Storage.widgetPaletteKey = "widgetPalette"` constant — this old single-slot key was never used by any code path after the migration.

### spx-uiux-verifier
- No issues reported — all 7 checks passed.
