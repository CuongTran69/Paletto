import Foundation

/// Represents a complete color palette with metadata
struct ColorPalette: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var colors: [PaletteColor]
    let createdAt: Date
    var updatedAt: Date
    var sourceImageData: Data?
    var version: Int
    var tags: [String]

    private enum CodingKeys: String, CodingKey {
        case id, name, colors, createdAt, updatedAt, sourceImageData, version, tags
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        colors: [PaletteColor] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sourceImageData: Data? = nil,
        version: Int = 2,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.colors = colors
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceImageData = sourceImageData
        self.version = version
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colors = try container.decode([PaletteColor].self, forKey: .colors)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sourceImageData = try container.decodeIfPresent(Data.self, forKey: .sourceImageData)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Formatted creation date
    var formattedDate: String {
        Self.dateFormatter.string(from: createdAt)
    }
}

