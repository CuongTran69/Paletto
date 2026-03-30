# Palette Tags

## ADDED Requirements

### Requirement: Tags field on ColorPalette
The `ColorPalette` model SHALL include a `tags: [String]` field, defaulting to an empty array. The field SHALL be persisted to JSON alongside the existing palette data. The palette version SHALL be incremented to 2.

#### Scenario: New palette created with no tags
- **WHEN** user creates a new palette and saves it
- **THEN** the palette is saved with `tags: []` and `version: 2`

#### Scenario: Existing palette migrated on first load
- **WHEN** `loadAll()` reads a palette with `version: 1` (missing tags field)
- **THEN** `PaletteMigration.migrateIfNeeded` sets `tags: []`, updates `version` to 2, and writes the palette back to disk

#### Scenario: Palette saved after adding tags
- **WHEN** user adds tags `"nature"` and `"brand"` to a palette and saves
- **THEN** the palette JSON includes `"tags": ["nature", "brand"]` and `version: 2`

### Requirement: Add tag to palette
The system SHALL allow users to add a tag to a palette. Adding a tag that already exists on that palette is a no-op (no duplicate). Maximum tags per palette is 20. Maximum tag name length is 50 characters.

#### Scenario: Add valid tag
- **WHEN** user adds tag `"nature"` to a palette that has no tags
- **THEN** palette's tags become `["nature"]`

#### Scenario: Add tag exceeding max length
- **WHEN** user adds a tag with 51 or more characters
- **THEN** an inline error appears: "Tag name must be 50 characters or fewer." The tag is NOT added.

#### Scenario: Add tag exceeding max count
- **WHEN** user adds a 21st tag to a palette that already has 20 tags
- **THEN** an inline error appears: "Maximum 20 tags per palette." The tag is NOT added.

#### Scenario: Add duplicate tag
- **WHEN** user adds tag `"nature"` to a palette that already has tag `"nature"`
- **THEN** the palette's tags remain `["nature"]` (no duplicate added)

### Requirement: Remove tag from palette
The system SHALL allow users to remove a tag from a palette.

#### Scenario: Remove existing tag
- **WHEN** user removes tag `"nature"` from a palette with tags `["nature", "brand"]`
- **THEN** palette's tags become `["brand"]`

#### Scenario: Remove non-existent tag
- **WHEN** user attempts to remove tag `"food"` from a palette with tags `["nature"]`
- **THEN** the palette's tags remain `["nature"]` (no-op)

### Requirement: Tag filter bar in Library
The Library tab SHALL display a horizontal scrollable tag filter bar above the palette list. The bar shows an "All" chip and one chip per unique tag found across all palettes. Tapping a chip filters the list to show only palettes with that tag.

#### Scenario: Filter by tag
- **WHEN** user taps the `"nature"` tag chip
- **THEN** the palette list shows only palettes that have tag `"nature"`

#### Scenario: Filter "All" shows all palettes
- **WHEN** user taps the "All" chip
- **THEN** the palette list shows all palettes regardless of their tags

#### Scenario: Tag chip shows count
- **WHEN** 3 palettes have tag `"nature"`
- **THEN** the `"nature"` chip displays count as `(3)`

#### Scenario: Tag chip not shown for palette's current tag list
- **WHEN** a palette's tags change (add/remove) while a tag filter is active
- **THEN** the palette is immediately included or excluded from the filtered list accordingly

### Requirement: New tag creation
The tag filter bar SHALL include a "+ New Tag" chip. Tapping it opens an inline text field. Entering a valid tag name and confirming adds the tag to the current palette (when inside Palette Detail) or creates a filter for all palettes containing that tag (when in Library).

#### Scenario: Create tag from filter bar in Library
- **WHEN** user taps "+ New Tag" in Library and enters `"spring"`
- **THEN** a tag filter for `"spring"` is added to the chip bar and is selected

#### Scenario: Create tag from Palette Detail
- **WHEN** user taps "+ New Tag" in Palette Detail and enters `"spring"`
- **THEN** the tag `"spring"` is added to the current palette

#### Scenario: Empty tag name rejected
- **WHEN** user enters an empty or whitespace-only tag name
- **THEN** an inline error appears: "Tag name cannot be empty." The tag is NOT added.

#### Scenario: Tag with "/" character rejected
- **WHEN** user enters a tag containing the "/" character
- **THAN** an inline error appears: "Tags cannot contain '/'." The tag is NOT added.

### Requirement: Tag display in Library list
Each `PaletteRowView` in the Library list SHALL display tag indicators when the palette has tags.

#### Scenario: Palette with tags shows tag chips
- **WHEN** a palette has tags `["nature", "brand"]`
- **THEN** the palette row shows compact tag chips below the color strip

#### Scenario: Palette with no tags shows no tag indicators
- **WHEN** a palette has an empty tags array
- **THEN** the palette row shows no tag chips

### Requirement: Tag editing in Palette Detail
Palette Detail view SHALL provide a tag editor section where users can view, add, and remove tags for the current palette.

#### Scenario: View tags
- **WHEN** user opens Palette Detail for a palette with tags `["nature"]`
- **THEN** the tag editor shows one chip `"nature"` with an "×" remove button

#### Scenario: Add tag via detail editor
- **WHEN** user taps "+ Add Tag" in Palette Detail and enters `"app-ui"`
- **THEN** the tag `"app-ui"` is added to the palette's tags

#### Scenario: Remove tag via detail editor
- **WHEN** user taps "×" on tag chip `"nature"` in Palette Detail
- **THEN** `"nature"` is removed from the palette's tags

### Requirement: Tag filtering combines with search
The tag filter bar SHALL work in combination with the existing search bar. When both a tag filter and search text are active, the list shows palettes matching both criteria.

#### Scenario: Combined tag and search filter
- **WHEN** user has selected tag `"nature"` and typed `"sunset"` in the search bar
- **THEN** the list shows only palettes that have tag `"nature"` AND whose name contains `"sunset"`
