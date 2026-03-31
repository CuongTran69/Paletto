# Palette Folders

## ADDED Requirements

### Requirement: Folder data model
The system SHALL define a `Folder` struct with fields: `id` (UUID), `name` (String), `paletteIds` ([UUID]), `createdAt` (Date), `updatedAt` (Date). Folders are persisted as a single `folders.json` file in the Application Support directory. Maximum 50 folders; maximum folder name length is 100 characters.

#### Scenario: Create first folder
- **WHEN** user creates a folder named `"Brand Colors"`
- **THEN** `folders.json` contains one folder with a unique UUID, name `"Brand Colors"`, empty `paletteIds`, and current timestamp as `createdAt`

#### Scenario: Folder name exceeds max length
- **WHEN** user creates a folder with a name of 101+ characters
- **THEN** an inline error appears: "Folder name must be 100 characters or fewer." The folder is NOT created.

#### Scenario: Folder count at maximum
- **WHEN** user already has 50 folders and attempts to create a 51st folder
- **THEN** an inline error appears: "Maximum 50 folders allowed." The folder is NOT created.

### Requirement: Create folder
The Library tab SHALL provide a way to create new folders. Folders are created empty (no palettes assigned).

#### Scenario: Create folder via Library section
- **WHEN** user taps "+ New Folder" in the My Folders section
- **THEN** an alert/sheet appears prompting for folder name
- **AND** user enters `"Spring 2026"` and confirms
- **THEN** a new folder named `"Spring 2026"` is saved to `folders.json` and appears in the My Folders section

### Requirement: Rename folder
The system SHALL allow users to rename an existing folder.

#### Scenario: Rename folder
- **WHEN** user long-presses or uses context menu on folder `"Spring 2026"` and selects "Rename"
- **THEN** the folder name becomes editable
- **AND** user changes it to `"Spring Colors"`
- **THEN** `folders.json` is updated and the UI reflects the new name

#### Scenario: Rename folder to duplicate name
- **WHEN** user renames folder `"Spring"` to `"Nature"` and a folder named `"Nature"` already exists
- **THEN** an inline error appears: "A folder with this name already exists." The rename is NOT saved.

### Requirement: Delete folder
The system SHALL allow users to delete a folder. Deleting a folder does NOT delete the palettes inside — palettes become uncategorized (no folder membership).

#### Scenario: Delete folder via context menu
- **WHEN** user uses context menu on folder `"Spring"` and selects "Delete"
- **THEN** a confirmation alert appears: "Delete folder 'Spring'? Palettes will become uncategorized."
- **AND** user confirms
- **THEN** the folder is removed from `folders.json` and palettes lose folder membership (no data deleted)

#### Scenario: Delete folder cancels
- **WHEN** user initiates folder deletion and taps "Cancel" in the confirmation alert
- **THEN** the folder remains unchanged

### Requirement: Assign palette to folder
The system SHALL allow users to assign a palette to a folder. A palette belongs to exactly one folder or zero folders (uncategorized).

#### Scenario: Assign palette to folder from Palette Detail
- **WHEN** user opens Palette Detail and uses the folder picker to assign the palette to folder `"Brand Colors"`
- **THEN** the palette's `folderId` reference is updated and the folder's `paletteIds` array includes this palette's UUID

#### Scenario: Move palette between folders
- **WHEN** a palette is currently in folder `"Spring"` and user moves it to folder `"Nature"`
- **THEN** `"Spring"` folder's `paletteIds` no longer contains this palette's UUID
- **AND** `"Nature"` folder's `paletteIds` contains this palette's UUID

#### Scenario: Uncategorize palette (remove from folder)
- **WHEN** user assigns a palette to "No Folder" / "Uncategorized"
- **THEN** the palette is removed from its current folder's `paletteIds`
- **AND** the palette has no folder membership

### Requirement: Folder section in Library
The Library tab SHALL display a "My Folders" collapsible section above the "All Palettes" section. Each folder row shows the folder name and palette count.

#### Scenario: Collapse folder section
- **WHEN** user taps the collapse chevron on "My Folders"
- **THEN** the folder list collapses and only the section header remains visible

#### Scenario: Expand folder section
- **WHEN** user taps the expand chevron on collapsed "My Folders"
- **THEN** all folder rows become visible

#### Scenario: Folder with no palettes
- **WHEN** a folder exists with 0 palettes
- **THEN** the folder row shows count `(0)` and remains visible in the list

### Requirement: Folder row in Library
Each folder row in the My Folders section SHALL be tappable and show the folder name with palette count.

#### Scenario: Tap folder row
- **WHEN** user taps folder row `"Brand Colors (4)"`
- **THEN** the view navigates to a filtered palette list showing only palettes in that folder

#### Scenario: Long-press folder row
- **WHEN** user long-presses folder row `"Brand Colors"`
- **THEN** a context menu appears with options: "Rename", "Delete"

### Requirement: Palette list filtered by folder
When viewing a folder, the palette list shows only palettes in that folder. A back button or breadcrumb returns to the full Library view.

#### Scenario: Navigate into folder
- **WHEN** user taps folder `"Brand Colors"`
- **THEN** the view shows only palettes assigned to `"Brand Colors"`
- **AND** a navigation back affordance is visible

#### Scenario: Empty folder view
- **WHEN** user navigates into a folder with 0 palettes
- **THEN** an empty state appears: "This folder is empty. Assign palettes from Palette Detail."

### Requirement: Folder persistence
Folder data SHALL persist across app launches. If `folders.json` is missing or corrupted, the system initializes an empty folder list (no crash).

#### Scenario: Folders persist after app restart
- **WHEN** user creates folders and assigns palettes
- **AND** closes and reopens the app
- **THEN** all folders and assignments are restored

#### Scenario: Corrupted folders.json
- **WHEN** `folders.json` contains invalid JSON
- **THEN** `FolderStorageService` initializes an empty folder list
- **AND** logs a warning message

### Requirement: Concurrent folder and palette operations
Folder operations (create, rename, delete) SHALL be atomic and safe for concurrent access. Folder modifications do NOT affect palette file integrity.

#### Scenario: Create folder while palettes are loading
- **WHEN** user creates a new folder while `loadAll()` is still in progress
- **THEN** the folder is created successfully without interrupting palette loading
