# Tasks: Palette Animation Preview

## 1. PaletteColor — Add AnimationMode enum and animatedColor method

- [x] 1.1 Add `AnimationMode` enum to `PaletteColor.swift` with cases: `off`, `pulsing`, `hueRotation`, `brightnessBreathing` — conforming to `CaseIterable`, `Identifiable`, `Codable` ← (verify: enum has exactly 4 cases, all conformances present)
- [x] 1.2 Add `animatedColor(for: ColorRole, mode: AnimationMode, progress: Double) -> Color` method to `PaletteColor` per design spec ← (verify: returns correct Color for each mode, hue wraps at 360, brightness clamped to 0..1)
- [x] 1.3 Add localization keys to `Localizable.strings`: `preview.animation.off`, `preview.animation.pulsing`, `preview.animation.hueRotation`, `preview.animation.brightnessBreathing`, `preview.animation.mode`

## 2. SettingsManager — Add previewAnimationEnabled

- [x] 2.1 Add `previewAnimationEnabled: Bool` computed property to `SettingsManager` with UserDefaults backing, key `"previewAnimationEnabled"`, default `true` ← (verify: setting persists across app launches, defaults to true on fresh install)

## 3. PaletteDetailView — Animation state and lifecycle

- [x] 3.1 Add `@State private var animationProgress: Double = 0` (drives 0..<1 animation cycle)
- [x] 3.2 Add `@State private var animationTimer: Timer?` for the 60fps ticker
- [x] 3.3 Add `startAnimationCycle()` private function per design: checks `settingsManager.previewAnimationEnabled`, checks `@AccessibilityReduceMotion`, starts `Timer.scheduledTimer` at 60fps interval, increments `animationProgress` using `Date()` delta, wraps at 1.0 ← (verify: timer starts on appear, increments progress at ~60fps, cycle duration ~2.5s)
- [x] 3.4 Add `stopAnimationCycle()` private function: invalidates timer, resets `animationProgress` to 0
- [x] 3.5 Add `.onAppear { startAnimationCycle() }` modifier to `PaletteDetailView` body
- [x] 3.6 Add `.onDisappear { stopAnimationCycle() }` modifier to `PaletteDetailView` body ← (verify: animation stops and resets when navigating away, restarts on re-appear)

## 4. PaletteDetailView — Animation mode picker

- [x] 4.1 Add `@State private var animationMode: AnimationMode = .off` ← (verify: defaults to .off on first open)
- [x] 4.2 Add a `Picker` with `.pickerStyle(.segmented)` for `AnimationMode.allCases` in `previewSection`, labeled with `L10n.previewAnimationMode.localized` ← (verify: picker shows 4 segments, Off is first and default)
- [x] 4.3 Update `startAnimationCycle()` to check `animationMode != .off` before starting timer
- [x] 4.4 When `animationMode` changes to `.off`, call `stopAnimationCycle()` immediately

## 5. PreviewCardView — Animation integration

- [x] 5.1 Add `animationMode: AnimationMode` and `animationProgress: Double` parameters to `PreviewCardView` struct signature ← (verify: PreviewCardView renders correctly with default .off mode)
- [x] 5.2 Replace all static `palette.color(for: .X)?.color ?? .fallback` usages in `appCardLayout`, `dashboardLayout`, `blogPostLayout` with `palette.animatedColor(for: .X, mode: animationMode, progress: animationProgress)` ← (verify: all three styles show animated colors when mode is non-off, static when .off)
- [x] 5.3 Pass `animationMode` and `animationProgress` from `PaletteDetailView.previewSection` down to the `PreviewCardView` instantiation

## 6. SettingsView — Global toggle

- [x] 6.1 Add a `Toggle` row in `SettingsView` with label `L10n.settingsPreviewAnimation.localized` bound to `settingsManager.previewAnimationEnabled` ← (verify: toggle persists setting, defaults to on)

## 7. Localization strings

- [x] 7.1 Add `preview.animation.off`, `preview.animation.pulsing`, `preview.animation.hueRotation`, `preview.animation.brightnessBreathing`, `preview.animation.mode`, `settings.preview.animation` to `Localizable.strings` (English values)

## 8. Unit Tests — PaletteAnimationTests

- [x] 8.1 Create `PaletteAnimationTests.swift` in `PalettoTests/`
- [x] 8.2 Test: `testAnimatedColorPulsingOscillatesBrightness` — create PaletteColor, call `animatedColor(for: .primary, mode: .pulsing, progress:)` at progress 0, 0.25, 0.5, assert brightness values follow sine curve between 0.7 and 1.0 ← (verify: brightness at progress=0 is 0.7, at progress=0.5 is 1.0)
- [x] 8.3 Test: `testAnimatedColorHueRotationWrapsAt360` — call `animatedColor(for: .primary, mode: .hueRotation, progress: 0)` and `progress: 1.0`, assert hue wraps correctly ← (verify: hue at progress=0 equals original, hue at progress=1 equals original modulo 360)
- [x] 8.4 Test: `testAnimatedColorBrightnessBreathingStaysInRange` — create PaletteColor with brightness 0.3, call at progress 0.25 and 0.75, assert resulting brightness is clamped to [0, 1] ← (verify: no out-of-range values produced)
- [x] 8.5 Test: `testAnimatedColorOffReturnsStaticColor` — assert `animatedColor(for: .primary, mode: .off, progress: 0.5)` returns the same color as `color` ← (verify: .off mode ignores progress parameter)
- [x] 8.6 Test: `testSettingsPreviewAnimationDefault` — assert `SettingsManager().previewAnimationEnabled` defaults to `true` on fresh install ← (verify: first-launch default is true)
- [x] 8.7 Test: `testAnimationModeAllCases` — assert `AnimationMode.allCases.count == 4` ← (verify: exactly 4 modes)
