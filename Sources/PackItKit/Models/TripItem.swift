import Foundation

public struct TripItem: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String?
    public var owner: String?
    public var priority: Priority
    public var isPacked: Bool
    public var notes: String?
    public var dueDate: Date?
    public var sourceTemplateItemID: UUID?
    public var isAdHoc: Bool
    public var quantity: Int

    public init(id: UUID = UUID(), name: String, category: String? = nil, owner: String? = nil, priority: Priority = .medium, isPacked: Bool = false, notes: String? = nil, dueDate: Date? = nil, sourceTemplateItemID: UUID? = nil, isAdHoc: Bool = false, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.category = category
        self.owner = owner
        self.priority = priority
        self.isPacked = isPacked
        self.notes = notes
        self.dueDate = dueDate
        self.sourceTemplateItemID = sourceTemplateItemID
        self.isAdHoc = isAdHoc
        self.quantity = max(1, quantity)
    }

    /// Create a trip item from a template item.
    public init(from templateItem: TemplateItem) {
        self.id = UUID()
        self.name = templateItem.name
        self.category = templateItem.category
        self.owner = templateItem.owner
        self.priority = templateItem.priority
        self.isPacked = false
        self.notes = templateItem.notes
        self.dueDate = nil
        self.sourceTemplateItemID = templateItem.id
        self.isAdHoc = false
        self.quantity = templateItem.quantity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        isPacked = try container.decodeIfPresent(Bool.self, forKey: .isPacked) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        sourceTemplateItemID = try container.decodeIfPresent(UUID.self, forKey: .sourceTemplateItemID)
        isAdHoc = try container.decodeIfPresent(Bool.self, forKey: .isAdHoc) ?? false
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }

    public var isOverdue: Bool {
        guard let due = dueDate, !isPacked else { return false }
        return due < .now
    }
}
