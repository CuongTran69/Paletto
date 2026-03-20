## [2026-03-19] Round 1 (from spx-verify → spx-apply fix)

### spx-verifier
- Fixed: Invalid UUID deep link (`paletto://palette/{invalid-string}`) now falls back to Library tab silently instead of showing error alert. Added early return with `selectedTab = 2` when path is present but UUID parsing fails in `PalettoApp.swift:handleIncomingURL`.

### spx-uiux-verifier
- Fixed: Added `.accessibilityLabel(L10n.detailNameConfirmA11y.localized)` to checkmark (confirm name) button in `PaletteDetailView.swift`. Added localization key `detail.name.confirm.accessibility` and translations in en.json ("Confirm palette name") and vi.json ("Xác nhận tên bảng màu").
- Fixed: Added error state display in `PaletteListView.swift` — new `errorState(_:)` view with error icon, message, and retry button. Added localization keys `library.error.title` and `library.error.retry` with translations. Also added `errorMessage = nil` on successful load in `PaletteListViewModel.swift` to clear stale errors.

## [2026-03-20] Round 2 (from spx-apply auto-verify)

### spx-uiux-verifier
- Fixed: Added `.accessibilityHidden(true)` to decorative error icon (`exclamationmark.triangle`) in `PaletteListView.swift:errorState(_:)` so VoiceOver no longer announces it separately from the error text.

### spx-arch-verifier
- Fixed: Extracted `onChangeCompat(of:perform:)` from `private extension View` in `SettingsView.swift` to shared `Paletto/Core/Extensions/View+OnChangeCompat.swift` (now `extension View`, not private). Updated `PaletteListView.swift` to use `onChangeCompat` instead of raw `.onChange(of:)` for consistency with project convention.

## [2026-03-20] Round 3 (from spx-apply auto-verify)

### spx-uiux-verifier
- Fixed: Added `.accessibilityHidden(true)` to decorative `exclamationmark.triangle.fill` icon in role-assignment hint banner in `PaletteDetailView.swift:226` so VoiceOver no longer announces it separately.
- Fixed: Added `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `PaletteDetailView` and updated preview card animation at line 275 to use `reduceMotion ? .none : .easeInOut(...)` to respect prefers-reduced-motion.

