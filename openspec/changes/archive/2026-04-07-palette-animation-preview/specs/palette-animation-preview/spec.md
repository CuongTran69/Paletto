# palette-animation-preview

## ADDED Requirements

### Requirement: Animation Mode Picker
The system SHALL display an animation mode picker in the Palette Detail preview section header, offering four options: Off, Pulsing, Hue Rotation, and Brightness Breathing. The picker uses a segmented control style.

#### Scenario: Picker displays four options
- **WHEN** the user navigates to a Palette Detail view
- **THEN** a segmented picker titled with the animation mode label is visible above the preview card
- **AND** the picker shows exactly four segments: Off, Pulsing, Hue Rotation, Brightness Breathing

#### Scenario: Picker defaults to Off
- **WHEN** the user opens a Palette Detail view for the first time after the feature is installed
- **THEN** the picker selection is set to Off
- **AND** no animation runs

#### Scenario: Picker mode change stops animation when Off selected
- **WHEN** an animation is currently running
- **AND** the user selects Off in the picker
- **THEN** the animation timer stops immediately
- **AND** `animationProgress` resets to 0
- **AND** all preview card colors return to their static values

### Requirement: Pulsing Animation
When the Pulsing animation mode is active, the system SHALL animate the brightness of each color between 70% and 100% over a 2.5-second cycle using a sine-wave curve, while keeping hue and saturation constant.

#### Scenario: Pulsing animates brightness only
- **WHEN** Pulsing mode is active
- **AND** the animation is running (reduceMotion is off, global setting is on)
- **THEN** each color's hue value remains unchanged from the palette
- **AND** each color's saturation value remains unchanged from the palette
- **AND** each color's brightness oscillates between 0.7 and 1.0 following a sine curve
- **AND** one complete cycle takes approximately 2.5 seconds

#### Scenario: Pulsing applies to all three preview styles
- **WHEN** Pulsing mode is active
- **THEN** the appCard layout colors animate
- **AND** the dashboard layout colors animate
- **AND** the blogPost layout colors animate
- **AND** all three styles animate in sync (same progress value)

### Requirement: Hue Rotation Animation
When the Hue Rotation animation mode is active, the system SHALL cycle the hue value of each color from 0° to 360° over a 2.5-second cycle, while keeping saturation and brightness constant.

#### Scenario: Hue rotation cycles hue only
- **WHEN** Hue Rotation mode is active
- **AND** the animation is running (reduceMotion is off, global setting is on)
- **THEN** each color's hue value increases continuously from 0° to 360°
- **AND** each color's saturation value remains unchanged from the palette
- **AND** each color's brightness value remains unchanged from the palette
- **AND** one complete cycle takes approximately 2.5 seconds
- **AND** the hue wraps from 360° back to 0° seamlessly

#### Scenario: Hue rotation wraps correctly at 360 degrees
- **WHEN** Hue Rotation mode is active
- **AND** the progress value reaches 1.0
- **THEN** hue wraps to 0° (equivalent to 360°)
- **AND** the animation continues seamlessly without a visible jump

### Requirement: Brightness Breathing Animation
When the Brightness Breathing animation mode is active, the system SHALL oscillate each color's brightness by ±20% around its original value using a sine wave, while keeping hue and saturation constant.

#### Scenario: Brightness breathing modifies brightness around original value
- **WHEN** Brightness Breathing mode is active
- **AND** the animation is running (reduceMotion is off, global setting is on)
- **AND** a color has original brightness B (0 ≤ B ≤ 1)
- **THEN** its animated brightness = B + (B - 0.5) × 0.4 × sin(progress × 2π)
- **AND** this results in brightness oscillating between B - 20%×(B-0.5) and B + 20%×(B-0.5)
- **AND** the oscillation takes approximately 2.5 seconds per cycle
- **AND** hue and saturation remain unchanged

#### Scenario: Brightness breathing never exceeds valid range
- **WHEN** Brightness Breathing mode is active
- **AND** the brightness calculation would produce a value outside [0, 1]
- **THEN** the value is clamped to the valid range before being applied

### Requirement: Animation Auto-Start
The system SHALL automatically start the animation cycle when the PaletteDetailView appears, if both the global preview animation setting is enabled and the system accessibilityReduceMotion preference is off.

#### Scenario: Animation starts on appear when enabled
- **WHEN** `PaletteDetailView` appears on screen
- **AND** `settingsManager.previewAnimationEnabled` is true
- **AND** `accessibilityReduceMotion` environment value is false
- **AND** `animationMode` is not set to Off
- **THEN** the animation timer starts immediately
- **AND** `animationProgress` begins incrementing

#### Scenario: Animation does not start when global setting is off
- **WHEN** `PaletteDetailView` appears
- **AND** `settingsManager.previewAnimationEnabled` is false
- **THEN** the animation timer does not start
- **AND** the preview card shows static colors
- **AND** the picker still displays and allows mode selection

#### Scenario: Animation does not start when reduceMotion is on
- **WHEN** `PaletteDetailView` appears
- **AND** `settingsManager.previewAnimationEnabled` is true
- **AND** `accessibilityReduceMotion` environment value is true
- **THEN** the animation timer does not start
- **AND** the preview card shows static colors

### Requirement: Animation Stops on Disappear
The system SHALL stop the animation timer and reset `animationProgress` to 0 when the PaletteDetailView disappears.

#### Scenario: Animation stops on disappear
- **WHEN** `PaletteDetailView` disappears from the view hierarchy
- **THEN** the animation timer is invalidated
- **AND** `animationProgress` is reset to 0

#### Scenario: Animation restarts correctly after background return
- **WHEN** `PaletteDetailView` re-appears after being disappeared
- **AND** the conditions for auto-start are met
- **THEN** a new animation timer is created and started
- **AND** `animationProgress` begins from 0

### Requirement: Global Animation Toggle in Settings
The system SHALL provide a global on/off toggle for the animation preview feature in the Settings view. When disabled, animation never runs regardless of the mode picker selection.

#### Scenario: Settings toggle disables animation globally
- **WHEN** the user turns off the "Preview Animation" toggle in Settings
- **AND** the user navigates to any Palette Detail view
- **THEN** the animation timer never starts regardless of the mode picker selection
- **AND** the preview card shows static colors

#### Scenario: Settings toggle persists across app launches
- **WHEN** the user enables the "Preview Animation" toggle in Settings
- **AND** the user terminates and relaunches the app
- **THEN** the setting remains enabled
- **AND** the animation feature behaves as enabled

#### Scenario: Default value is enabled
- **WHEN** the user installs the app for the first time
- **THEN** the "Preview Animation" setting defaults to true (enabled)

### Requirement: Accessibility Reduce Motion Integration
The system SHALL automatically disable the animation preview when the iOS system preference `accessibilityReduceMotion` is enabled, regardless of the global setting or mode picker selection.

#### Scenario: Animation respects system reduceMotion
- **WHEN** the device has `accessibilityReduceMotion` enabled
- **AND** the user navigates to a Palette Detail view
- **AND** `settingsManager.previewAnimationEnabled` is true
- **AND** the mode picker is set to Pulsing (or any non-Off mode)
- **THEN** the animation timer does not start
- **AND** the preview card shows static colors
- **AND** the picker remains visible and functional

#### Scenario: Changing reduceMotion while viewing detail has no effect (no runtime detection)
- **WHEN** the user has `accessibilityReduceMotion` disabled
- **AND** the animation is currently running
- **AND** the user enables `accessibilityReduceMotion` in iOS Settings
- **THEN** the running animation continues until the user navigates away
- **AND** on next visit to PaletteDetailView, the new preference is respected
