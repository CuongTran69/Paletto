## Why

The palette preview card shows how colors work together in realistic UI layouts (app card, dashboard, blog post), but the static display doesn't convey how those colors feel when actually used in a live UI. Adding live animated previews — pulsing buttons, hue-rotating gradients, brightness-breathing accents — gives designers an immediate sense of the palette's energy and mood before committing to use.

## What Changes

- New **Animation Mode Picker** segmented control in the Palette Detail view preview section, with 4 modes: **Off**, **Pulsing**, **Hue Rotation**, **Brightness Breathing**
- **Global on/off toggle** in the Settings view (`previewAnimationEnabled`)
- **Auto-start** of animation when PaletteDetailView appears (if enabled in settings and `accessibilityReduceMotion` is off)
- All three preview card styles (appCard, dashboard, blogPost) animate their color usages simultaneously
- Animation respects iOS `accessibilityReduceMotion` — automatically disabled when the system preference is on
- Medium animation cycle speed (2–3 seconds per full cycle)
- PaletteColor gains a new `AnimationMode` enum and an `animatedColor(for:)` method

## Capabilities

### New Capabilities
- `palette-animation-preview`: Live animated color preview with pulsing, hue rotation, and brightness breathing effects applied to all three preview card styles

### Modified Capabilities
- (none — no existing spec behavior changes)

## Impact

- **New files**: `AnimationMode.swift` (enum), `AnimatedColorModifier.swift` (view modifier)
- **Modified files**: `PaletteColor.swift` (add `animatedColor(for:)`), `PreviewCardView.swift` (animation modifiers), `PaletteDetailView.swift` (animation mode picker + state), `SettingsView.swift` (global toggle), `SettingsManager.swift` (`previewAnimationEnabled` key)
- **New localization keys**: animation mode labels, settings toggle label
- **Dependency**: Uses existing `@Environment(\.accessibilityReduceMotion)` already present in `PaletteDetailView`
