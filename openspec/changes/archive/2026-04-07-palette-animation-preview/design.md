## Context

The Paletto app shows a palette preview using `PreviewCardView` with three static layout styles (appCard, dashboard, blogPost). Each style uses `palette.color(for:)` to retrieve a `PaletteColor` per role (background, primary, secondary, accent, text), then converts it to SwiftUI `Color` via the `color` computed property.

The goal is to add a live animation layer that transforms the colors over time, while keeping the static layout and color-role mapping unchanged.

**Constraints:**
- Must work with the existing `PaletteColor` model (`.hue`, `.saturation`, `.brightness` computed properties already exist)
- Must respect iOS `accessibilityReduceMotion` — animation must not run when the system preference is on
- Animation auto-starts on view appear; user can switch modes via a picker
- Global on/off in Settings — animation is completely disabled when false
- All three preview styles animate simultaneously from the same palette
- Medium speed: 2–3 second cycle (angle progression of ~0.2–0.3 rad/s for hue rotation)

## Goals / Non-Goals

**Goals:**
- Animate color usages in all three preview card styles simultaneously
- Three animation modes: Pulsing (brightness), Hue Rotation (hue shift), Brightness Breathing (sine wave brightness)
- Animation mode picker in the preview section header (Off + 3 modes = 4 options)
- Global `previewAnimationEnabled` toggle in Settings view
- Auto-start animation when `PaletteDetailView` appears (if enabled globally and `accessibilityReduceMotion` is off)
- Zero animation when `accessibilityReduceMotion = true` regardless of other settings

**Non-Goals:**
- Animating the palette strip in `PaletteExtractionView` (different feature)
- Saving animation mode per palette (all palettes share the same global mode)
- Adjustable animation speed (fixed medium speed)

## Decisions

### 1. `AnimationMode` enum in `PaletteColor.swift`

Define the animation mode as a simple enum alongside `PaletteColor`:

```swift
enum AnimationMode: String, CaseIterable, Identifiable {
    case off
    case pulsing       // brightness oscillates 0.7→1.0→0.7
    case hueRotation   // hue cycles 0°→360°
    case brightnessBreathing // brightness ±20% around current value
}
```

This keeps the model self-contained. The enum lives in `PaletteColor.swift` because it operates on palette color values (HSB manipulation), not on views.

### 2. `animatedColor(for: ColorRole) -> Color` on `PaletteColor`

Add to `PaletteColor`:
```swift
func animatedColor(for role: ColorRole, mode: AnimationMode, progress: Double) -> Color
```

- `progress`: a `Double` in `0..<1` driven by a `Timer`-based or `withAnimation` cycle
- For `.off`, always returns `self.color`
- For `.pulsing`: `Color(hue: hue/360, saturation: saturation, brightness: 0.7 + 0.3 * progress, alpha: alpha)` — animates brightness from 70% to 100%
- For `.hueRotation`: `Color(hue: ((hue + progress * 360).truncatingRemainder(dividingBy: 360))/360, saturation: saturation, brightness: brightness, alpha: alpha)` — cycles hue 0→360
- For `.brightnessBreathing`: `Color(hue: hue/360, saturation: saturation, brightness: max(0, min(1, brightness + (brightness - 0.5) * 0.4 * sin(progress * 2 * .pi))), alpha: alpha)` — ±20% brightness around current value

**Why not a ViewModifier?** A view modifier approach (`SomeModifier(mode: .pulsing)`) would require injecting `progress` as `@State` into every color usage site. The `animatedColor(for:progress:)` method on `PaletteColor` keeps the animation math in the model, and `progress` becomes the single source of truth driven by one `@State` variable at the view level.

### 3. Central `animationProgress` `@State` in `PaletteDetailView`

```
PaletteDetailView
  @State private var animationProgress: Double = 0   // 0..<1
  @State private var animationMode: AnimationMode = .off
  @State private var animationTimer: Timer?

  onAppear: startAnimationCycle()
  onDisappear: stopAnimationCycle()
```

The `startAnimationCycle()` function:
1. Checks `settingsManager.previewAnimationEnabled` — if false, do nothing
2. Checks `@AccessibilityReduceMotion` — if true, do nothing
3. Sets `animationMode` to the saved/remembered mode (or `.off` if never set)
4. Starts a `Timer.scheduledTimer` with 16ms interval (~60fps) that increments `animationProgress` by `(1/cycleDuration) * 0.016`
5. Cycle duration = 2.5 seconds (medium speed)

The timer increments `animationProgress` modulo 1.0 (wraps to 0 after 1).

**Why Timer + Double instead of `SwiftUI.animation`?** SwiftUI's implicit animation ties to state changes with a fixed duration, making it hard to produce a continuous looping signal (sine wave, hue cycling) across a long duration. A `Timer` at 60fps with a `Double` progress value gives precise control over the animation curve and is straightforward to stop/start on view lifecycle.

### 4. `PreviewCardView` gets an `animationMode` + `progress` binding

```swift
struct PreviewCardView: View {
    let palette: ColorPalette
    var style: PreviewStyle = .appCard
    var animationMode: AnimationMode = .off   // new
    var animationProgress: Double = 0           // new
```

All internal color usages change from:
```swift
primaryColor   // was: palette.color(for: .primary)?.color ?? .blue
```
to:
```swift
palette.animatedColor(for: .primary, mode: animationMode, progress: animationProgress)
```

**Why not propagate the palette with an extension?** The `animatedColor(for:mode:progress:)` method is on `PaletteColor` (the model) because it computes a new color from the stored HSB values. The preview card already takes a `palette: ColorPalette` binding. Changing the color accessor at each usage site is the minimal, most direct approach — no new type needed.

### 5. Animation mode picker in `previewSection`

In the `previewSection` of `PaletteDetailView`, above or below the style picker:

```swift
Picker(L10n.previewAnimationMode.localized, selection: $animationMode) {
    Text(L10n.previewAnimationOff.localized).tag(AnimationMode.off)
    Text(L10n.previewAnimationPulsing.localized).tag(AnimationMode.pulsing)
    Text(L10n.previewAnimationHueRotation.localized).tag(AnimationMode.hueRotation)
    Text(L10n.previewAnimationBrightnessBreathing.localized).tag(AnimationMode.brightnessBreathing)
}
.pickerStyle(.segmented)
```

When `animationMode` changes to `.off`, the timer is stopped and `animationProgress` is reset to 0.

### 6. Settings toggle: `previewAnimationEnabled`

In `SettingsManager.swift`, add:
```swift
var previewAnimationEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: Keys.previewAnimationEnabled) }
    set { UserDefaults.standard.set(newValue, forKey: Keys.previewAnimationEnabled) }
}
```
Key: `"previewAnimationEnabled"`, default `true`.

In `SettingsView`, add a `Toggle` row:
```swift
Toggle(L10n.settingsPreviewAnimation.localized, isOn: $settingsManager.previewAnimationEnabled)
```

When this is off, `startAnimationCycle()` is a no-op. The picker still shows but animation never runs.

### 7. Accessibility: `@AccessibilityReduceMotion`

In `PaletteDetailView`:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

In `startAnimationCycle()`:
```swift
if reduceMotion { return }
```

Also, the animation picker remains visible and functional — the user can still select a mode. The animation simply does not run when `reduceMotion` is true. This is intentional: the picker lets users know what mode would be active, without forcing animation on them.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Timer at 60fps may cause battery drain if user leaves detail view open | Timer is stopped in `onDisappear`, started in `onAppear` — only runs while view is visible |
| `animationProgress` as `@State` causes 60 updates/second, potentially heavy | SwiftUI efficiently batches view updates; the color recalculation is cheap HSB math |
| Hue rotation on near-grayscale colors is visually imperceptible | Acceptable — the animation serves mood preview; grayscale palettes are a known edge case |
| Adding `AnimationMode` to `PaletteColor.swift` changes the model | Low risk — purely additive enum, no existing behavior changed |
| Timer-based animation can drift over time | Use `Date()` delta in each tick rather than fixed 0.016 increment for accuracy |
