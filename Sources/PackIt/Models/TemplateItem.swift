import Foundation

struct TemplateItem: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var category: String?
    var contextTags: [String]
    var priority: Priority
    var notes: String?

    init(id: UUID = UUID(), name: String, category: String? = nil, contextTags: [String] = [], priority: Priority = .medium, notes: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.contextTags = contextTags
        self.priority = priority
        self.notes = notes
    }
}
