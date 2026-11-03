# Extract Color Replace

## ADDED Requirements

### Requirement: Max color count is 10
The Extract tab's palette SHALL support up to 10 colors total, controlled by `Constants.Palette.maxColorCount`.

#### Scenario: Palette starts with k-means seed colors
- **WHEN** user selects an image with `defaultColorCount` set to 5
- **THEN** `extractedColors` is seeded with exactly 5 k-means colors

#### Scenario: Palette fills to 10 colors
- **WHEN** user has picked colors up to the maximum of 10
- **THEN** `extractedColors.count` equals `Constants.Palette.maxColorCount` (10)
- **AND** no more colors can be appended

### Requirement: User picks append below max
User-picked colors SHALL be appended to the palette while `extractedColors.count < maxColorCount`.

#### Scenario: Append while below max
- **WHEN** `extractedColors.count` is 7 and user picks a new color
- **THEN** the new color is appended (index 7)

#### Scenario: Append from empty state
- **WHEN** `extractedColors` is empty and user picks a new color
- **THEN** the new color is appended (index 0)

### Requirement: At max capacity, user picks replace in user-pick zone
When the palette is at `maxColorCount` (10), picking a new color SHALL replace an existing color within the user-pick zone (slots `[seedCount, maxCount - 1]`), cycling round-robin through all user-pick slots. Slots in the k-means zone (`[0, seedCount - 1]`) SHALL NOT be replaced.

#### Scenario: Round-robin replaces user-pick slots
- **WHEN** palette is at max (10 colors) with seedCount=5, and user picks 6 new colors sequentially
- **THEN** slots 5, 6, 7, 8, 9, 5 are replaced in order (round-robin over 5 user-pick slots)
- **AND** slots 0–4 (k-means zone) remain unchanged

#### Scenario: Round-robin covers all user-pick slots
- **WHEN** palette is at max (10 colors) with seedCount=3, and user picks colors
- **THEN** round-robin cycles through slots 3–9 (7 slots, not just 3)
- **AND** slots 0–2 (k-means zone) remain unchanged

#### Scenario: At max with default seed, replaces slots 5–9
- **WHEN** palette is at max (10 colors) with default seedCount=5
- **THEN** round-robin target indices cycle through 5, 6, 7, 8, 9

### Requirement: K-means zone refill before round-robin
When the palette is at `maxColorCount` (full) and the k-means zone has empty slots (due to deletion), a new user pick SHALL fill the first empty k-means slot instead of entering the round-robin.

#### Scenario: Refill deleted k-means slot
- **WHEN** palette is full (10 colors), user deletes the color at slot 2 (k-means zone)
- **AND** user picks a new color
- **THEN** the new color fills slot 2 (the deleted k-means slot)
- **AND** round-robin is NOT triggered

#### Scenario: Multiple empty k-means slots, picks fill first
- **WHEN** palette is full and slots 1 and 3 are empty (deleted from k-means zone)
- **AND** user picks a new color
- **THEN** slot 1 is filled (first empty slot by lowest index)

#### Scenario: No empty k-means slots triggers round-robin
- **WHEN** palette is full and k-means zone has no empty slots
- **AND** user picks a new color
- **THEN** round-robin replaces in user-pick zone

### Requirement: K-means zone can be appended into when below max
When `extractedColors.count < seedCount`, new user picks SHALL be appended (filling the k-means zone) rather than going to the user-pick zone.

#### Scenario: Picks fill k-means zone when below seed count
- **WHEN** palette has 3 k-means colors (seedCount=5) and user picks a color
- **THEN** the new color is appended to slot 3 (k-means zone, below seedCount)

### Requirement: Remove color from any slot
User SHALL be able to remove a color from any slot, including k-means zone slots.

#### Scenario: Remove k-means slot
- **WHEN** palette has 5 k-means colors and 5 user-pick colors
- **AND** user removes the color at slot 2
- **THEN** slot 2 becomes empty
- **AND** next user pick fills slot 2

### Requirement: Haptic feedback on add and remove
When haptic feedback is enabled, adding or removing a color SHALL trigger a selection haptic.

#### Scenario: Haptic on add picked color
- **WHEN** `hapticFeedbackEnabled` is true and user adds a picked color
- **THEN** `UISelectionFeedbackGenerator().selectionChanged()` is called

#### Scenario: Haptic on remove color
- **WHEN** `hapticFeedbackEnabled` is true and user removes a color
- **THEN** `UISelectionFeedbackGenerator().selectionChanged()` is called
