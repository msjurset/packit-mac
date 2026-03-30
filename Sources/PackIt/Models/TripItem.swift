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

    init(id: UUID = UUID(), name: String, category: String? = nil, priority: Priority = .medium, isPacked: Bool = false, notes: String? = nil, dueDate: Date? = nil, sourceTemplateItemID: UUID? = nil, isAdHoc: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.priority = priority
        self.isPacked = isPacked
        self.notes = notes
        self.dueDate = dueDate
        self.sourceTemplateItemID = sourceTemplateItemID
        self.isAdHoc = isAdHoc
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
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isPacked else { return false }
        return due < .now
    }
}
