## [2026-04-01] Round 1 (from spx-apply widget-multi-size-impl)

### spx-verifier
- Fixed: Make `SharedDataService` decoder date strategy explicit — added `d.dateDecodingStrategy = .iso8601` to the decoder closure (previously relied on implicit default)

### spx-arch-verifier
- Fixed: **[CRITICAL]** `roles` key mismatch — renamed `WidgetPalette.roles` → `WidgetPalette.colorRoles` in `SharedDataService.swift`. Both targets now use snake_case key `"colorRoles"` in JSON, consistent with `WidgetPaletteData.colorRoles` in widget extension. `JSONEncoder` outputs `"colorRoles"` matching the Codable property name. Widget `JSONDecoder` decodes it correctly.
- Fixed: **[LOW]** Removed dead `Constants.Storage.widgetPaletteKey = "widgetPalette"` constant — this old single-slot key was never used by any code path after the migration.

### spx-uiux-verifier
- No issues reported — all 7 checks passed.

---

## [2026-04-01] Round 2 (from spx-apply widget-multi-size-impl)

### spx-verifier / spx-arch-verifier
- Fixed: **[CRITICAL] iOS 16 crash** — `PalettoWidgetBundle.swift` was using `AppIntentConfiguration` directly (iOS 17+ only) with no conditional. Added `if #available(iOSApplicationExtension 17.0, *)` to use `AppIntentConfiguration` on iOS 17+ and `StaticConfiguration` fallback on iOS 16.
- Fixed: **[CRITICAL] App Group storage mismatch** — `PaletteStorageService` stored palettes in standard `ApplicationSupport` while widget used App Group container. Changed `palettesDirectory` to prefer `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` and added one-time migration from legacy directory on first launch.
- Fixed: **[BUG] VoiceOver accessibilityLabel** — `accessibilityLabel` expression `\(palette.colorRoles[safe: index] ?? nil)` always returned `"no role"` because `safe` already returns `String?`, so `?? nil` is always nil. Fixed to `\(palette.colorRoles[safe: index] ?? "no role")`.
- Fixed: **[CLEANUP]** Removed orphan `SelectWidgetPaletteIntent.swift` (old wrong version, 5227 bytes) from `PalettoWidget/` directory — file was not in Xcode project but present on disk.
- Fixed: **[CRITICAL — runtime crash]** `SelectWidgetPaletteIntent.perform()` used `JSONSerialization` with `as Any` cast for `nil` roles — `JSONSerialization` throws at runtime when any color has no role (nil is not a valid JSON property list type). Replaced entire body with `JSONEncoder` + existing `WidgetPalette`/`WidgetConfig` structs, consistent with `SharedDataService.setWidgetPalette()`. Also uses `Constants.Storage.widgetSlotKey(for:)` and `Constants.Storage.appGroupIdentifier` for consistency.

### spx-uiux-verifier
- No new UI/UX issues from this round.

### spx-test-verifier
- N/A — project has no test framework configured.
