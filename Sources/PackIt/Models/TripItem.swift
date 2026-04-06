import Foundation

struct TripItem: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var category: String?
    var priority: Priority
    var isPacked: Bool
    var notes: String?
    var dueDate: Date?
    var sourceTemplateItemID: UUID?
    var isAdHoc: Bool
    var quantity: Int

    init(id: UUID = UUID(), name: String, category: String? = nil, priority: Priority = .medium, isPacked: Bool = false, notes: String? = nil, dueDate: Date? = nil, sourceTemplateItemID: UUID? = nil, isAdHoc: Bool = false, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.category = category
        self.priority = priority
        self.isPacked = isPacked
        self.notes = notes
        self.dueDate = dueDate
        self.sourceTemplateItemID = sourceTemplateItemID
        self.isAdHoc = isAdHoc
        self.quantity = max(1, quantity)
    }

    /// Create a trip item from a template item.
    init(from templateItem: TemplateItem) {
        self.id = UUID()
        self.name = templateItem.name
        self.category = templateItem.category
        self.priority = templateItem.priority
        self.isPacked = false
        self.notes = templateItem.notes
        self.dueDate = nil
        self.sourceTemplateItemID = templateItem.id
        self.isAdHoc = false
        self.quantity = templateItem.quantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        isPacked = try container.decodeIfPresent(Bool.self, forKey: .isPacked) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        sourceTemplateItemID = try container.decodeIfPresent(UUID.self, forKey: .sourceTemplateItemID)
        isAdHoc = try container.decodeIfPresent(Bool.self, forKey: .isAdHoc) ?? false
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isPacked else { return false }
        return due < .now
    }
}
