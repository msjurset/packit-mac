import Foundation

struct TripTodo: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var text: String
    var isComplete: Bool
    var dueDate: Date?
    var priority: Priority

    init(id: UUID = UUID(), text: String, isComplete: Bool = false, dueDate: Date? = nil, priority: Priority = .medium) {
        self.id = id
        self.text = text
        self.isComplete = isComplete
        self.dueDate = dueDate
        self.priority = priority
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isComplete else { return false }
        return due < .now
    }
}
