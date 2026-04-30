import Foundation

public struct TripTodo: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var isComplete: Bool
    public var dueDate: Date?
    public var priority: Priority

    public init(id: UUID = UUID(), text: String, isComplete: Bool = false, dueDate: Date? = nil, priority: Priority = .medium) {
        self.id = id
        self.text = text
        self.isComplete = isComplete
        self.dueDate = dueDate
        self.priority = priority
    }

    public var isOverdue: Bool {
        guard let due = dueDate, !isComplete else { return false }
        return due < .now
    }
}
