import Foundation

/// Handles migration of ColorPalette data between versions
enum PaletteMigration {

    /// Current palette version
    static let currentVersion = 1

    /// Migrate a palette to the current version if needed
    /// Returns the palette unchanged if already current, or migrated if older
    static func migrateIfNeeded(_ palette: ColorPalette) -> ColorPalette {
        var migrated = palette

        // Future migrations go here:
        // if migrated.version < 2 { migrated = migrateV1toV2(migrated) }
        // if migrated.version < 3 { migrated = migrateV2toV3(migrated) }

        migrated.version = currentVersion
        return migrated
    }
}

