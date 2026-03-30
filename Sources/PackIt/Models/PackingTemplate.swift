import Foundation

struct PackingTemplate: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var items: [TemplateItem]
    var contextTags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, items: [TemplateItem] = [], contextTags: [String] = [], createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.contextTags = contextTags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var itemCount: Int { items.count }

    var categories: [String] {
        Array(Set(items.compactMap(\.category))).sorted()
    }

    mutating func touch() {
        updatedAt = .now
    }
}
