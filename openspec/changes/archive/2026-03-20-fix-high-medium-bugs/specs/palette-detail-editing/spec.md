## ADDED Requirements

### Requirement: Palette name edits are persisted on confirm
When the user edits a palette name in PaletteDetailView and confirms the edit (tap checkmark or press return), the updated name SHALL be saved to disk.

#### Scenario: User taps checkmark to confirm name edit
- **WHEN** user edits the palette name and taps the checkmark button
- **THEN** the updated name is persisted to disk via `PaletteStorageService`

#### Scenario: User presses return to confirm name edit
- **WHEN** user edits the palette name and presses the return key (onSubmit)
- **THEN** the updated name is persisted to disk via `PaletteStorageService`

#### Scenario: User navigates back after editing name
- **WHEN** user edits the palette name, confirms, and navigates back to the Library
- **THEN** the Library list displays the updated palette name

