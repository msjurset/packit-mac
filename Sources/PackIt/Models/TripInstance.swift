import Foundation

enum TripStatus: String, Codable, CaseIterable, Sendable {
    case planning
    case active
    case completed
    case archived

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .planning: return "pencil.and.list.clipboard"
        case .active: return "suitcase.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }
}

struct TripInstance: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var sourceTemplateIDs: [UUID]
    var departureDate: Date
    var returnDate: Date?
    var items: [TripItem]
    var todos: [TripTodo]
    var scratchNotes: String
    var status: TripStatus
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, sourceTemplateIDs: [UUID] = [], departureDate: Date = .now, returnDate: Date? = nil, items: [TripItem] = [], todos: [TripTodo] = [], scratchNotes: String = "", status: TripStatus = .planning, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.sourceTemplateIDs = sourceTemplateIDs
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.items = items
        self.todos = todos
        self.scratchNotes = scratchNotes
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var totalItems: Int { items.count }
    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(packedCount) / Double(totalItems)
    }

    var adHocItems: [TripItem] {
        items.filter(\.isAdHoc)
    }

    var overdueItems: [TripItem] {
        items.filter { $0.isOverdue && $0.priority >= .high }
    }

    var incompleteTodos: [TripTodo] {
        todos.filter { !$0.isComplete }
    }

    var isDepartureSoon: Bool {
        let daysUntil = Calendar.current.dateComponents([.day], from: .now, to: departureDate).day ?? 0
        return daysUntil >= 0 && daysUntil <= 3
    }

    mutating func touch() {
        updatedAt = .now
    }
}
