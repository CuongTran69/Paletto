import Foundation

/// Represents a complete color palette with metadata
struct ColorPalette: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var colors: [PaletteColor]
    let createdAt: Date
    var updatedAt: Date
    var sourceImageData: Data?

    init(
        id: UUID = UUID(),
        name: String = "",
        colors: [PaletteColor] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sourceImageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.colors = colors
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceImageData = sourceImageData
    }

    /// Returns colors filtered by a specific role
    func colors(for role: ColorRole) -> [PaletteColor] {
        colors.filter { $0.role == role }
    }

    /// Returns the first color with the given role, if any
    func color(for role: ColorRole) -> PaletteColor? {
        colors.first { $0.role == role }
    }

    /// Number of colors in the palette
    var colorCount: Int {
        colors.count
    }

    /// Whether all colors have assigned roles
    var allRolesAssigned: Bool {
        colors.allSatisfy { $0.role != nil }
    }

    /// Formatted creation date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

