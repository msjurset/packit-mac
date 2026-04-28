import Foundation

/// First-class category metadata: name + icon + color. Stored at
/// `~/.packit/categories.json`. Items still hold a plain `String?` for the
/// category — these records just decorate it.
struct ItemCategory: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var icon: String       // SF Symbol name
    var color: String      // CategoryColor.rawValue
    var rank: Int          // Manual ordering; ignored when sort mode is .name.

    init(id: UUID = UUID(), name: String, icon: String, color: String, rank: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.rank = rank
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, rank
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.icon = try c.decode(String.self, forKey: .icon)
        self.color = try c.decode(String.self, forKey: .color)
        self.rank = try c.decodeIfPresent(Int.self, forKey: .rank) ?? 0
    }
}

enum CategorySortMode: String, Codable, CaseIterable, Sendable {
    case name
    case manual
}

/// Curated palette of color tokens. Stored as raw strings so renaming
/// SwiftUI's color names doesn't break files on disk.
enum CategoryColor: String, CaseIterable, Codable, Sendable {
    case blue
    case teal
    case cyan
    case indigo
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case mint
    case brown
    case gray
}
