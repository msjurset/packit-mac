import Foundation

public struct TemplateItem: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String?
    public var owner: String?
    public var contextTags: [String]
    public var priority: Priority
    public var notes: String?
    public var quantity: Int

    public init(id: UUID = UUID(), name: String, category: String? = nil, owner: String? = nil, contextTags: [String] = [], priority: Priority = .medium, notes: String? = nil, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.category = category
        self.owner = owner
        self.contextTags = contextTags
        self.priority = priority
        self.notes = notes
        self.quantity = max(1, quantity)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        contextTags = try container.decodeIfPresent([String].self, forKey: .contextTags) ?? []
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }
}
