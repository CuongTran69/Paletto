import Foundation

/// Represents a folder used to organize palettes
struct Folder: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var paletteIds: [UUID]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        paletteIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.paletteIds = paletteIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
