import Foundation

/// Handles migration of ColorPalette data between versions
enum PaletteMigration {

    /// Current palette version
    static let currentVersion = 2

    /// Migrate a palette to the current version if needed
    /// Returns the palette unchanged if already current, or migrated if older
    static func migrateIfNeeded(_ palette: ColorPalette) -> ColorPalette {
        var migrated = palette

        if migrated.version < 2 {
            migrated = migrateToV2(migrated)
        }

        migrated.version = currentVersion
        return migrated
    }

    private static func migrateToV2(_ palette: ColorPalette) -> ColorPalette {
        var migrated = palette
        migrated.tags = []
        migrated.version = 2
        return migrated
    }
}

