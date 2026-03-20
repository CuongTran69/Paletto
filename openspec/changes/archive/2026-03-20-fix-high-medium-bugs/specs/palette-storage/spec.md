## ADDED Requirements

### Requirement: PaletteStorageService uses shared singleton instance
The PaletteStorageService SHALL provide a `static let shared` singleton instance. All ViewModels SHALL use `PaletteStorageService.shared` as their default storage service parameter.

#### Scenario: All ViewModels share the same storage queue
- **WHEN** multiple ViewModels perform concurrent file operations (save, delete, loadAll)
- **THEN** all operations are serialized through the same `fileQueue` from the shared instance

#### Scenario: Test injection still works
- **WHEN** a ViewModel is initialized with a custom `PaletteStorageServiceProtocol` implementation
- **THEN** the custom implementation is used instead of the shared singleton

#### Scenario: PalettoApp uses shared instance
- **WHEN** PalettoApp handles an incoming sharing URL and saves the imported palette
- **THEN** it uses `PaletteStorageService.shared` instead of a locally created instance

