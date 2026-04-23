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
    var icon: TripIcon
    var destination: TripDestination?
    var sourceTemplateIDs: [UUID]
    var departureDate: Date
    var returnDate: Date?
    var items: [TripItem]
    var prepTasks: [PrepTask]
    var todos: [TripTodo]
    var activities: [TripActivity]
    var procedures: [Procedure]
    var mealPlan: MealPlan?
    var referenceLinks: [ReferenceLink]
    var scratchNotes: String
    var status: TripStatus
    var version: Int
    var lastModifiedBy: String?
    var createdBy: String?
    var rank: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, icon: TripIcon = .suitcase, destination: TripDestination? = nil, sourceTemplateIDs: [UUID] = [], departureDate: Date = .now, returnDate: Date? = nil, items: [TripItem] = [], prepTasks: [PrepTask] = [], todos: [TripTodo] = [], activities: [TripActivity] = [], procedures: [Procedure] = [], mealPlan: MealPlan? = nil, referenceLinks: [ReferenceLink] = [], version: Int = 1, lastModifiedBy: String? = nil, createdBy: String? = nil, rank: Int = Int.max, scratchNotes: String = "", status: TripStatus = .planning, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.icon = icon
        self.destination = destination
        self.sourceTemplateIDs = sourceTemplateIDs
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.items = items
        self.prepTasks = prepTasks
        self.todos = todos
        self.activities = activities
        self.procedures = procedures
        self.mealPlan = mealPlan
        self.referenceLinks = referenceLinks
        self.scratchNotes = scratchNotes
        self.status = status
        self.version = version
        self.lastModifiedBy = lastModifiedBy
        self.createdBy = createdBy
        self.rank = rank
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(TripIcon.self, forKey: .icon) ?? .suitcase
        destination = try container.decodeIfPresent(TripDestination.self, forKey: .destination)
        sourceTemplateIDs = try container.decodeIfPresent([UUID].self, forKey: .sourceTemplateIDs) ?? []
        departureDate = try container.decodeIfPresent(Date.self, forKey: .departureDate) ?? .now
        returnDate = try container.decodeIfPresent(Date.self, forKey: .returnDate)
        items = try container.decodeIfPresent([TripItem].self, forKey: .items) ?? []
        prepTasks = try container.decodeIfPresent([PrepTask].self, forKey: .prepTasks) ?? []
        todos = try container.decodeIfPresent([TripTodo].self, forKey: .todos) ?? []
        activities = try container.decodeIfPresent([TripActivity].self, forKey: .activities) ?? []
        procedures = try container.decodeIfPresent([Procedure].self, forKey: .procedures) ?? []
        mealPlan = try container.decodeIfPresent(MealPlan.self, forKey: .mealPlan)
        referenceLinks = try container.decodeIfPresent([ReferenceLink].self, forKey: .referenceLinks) ?? []
        scratchNotes = try container.decodeIfPresent(String.self, forKey: .scratchNotes) ?? ""
        status = try container.decodeIfPresent(TripStatus.self, forKey: .status) ?? .planning
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        rank = try container.decodeIfPresent(Int.self, forKey: .rank) ?? Int.max
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
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

    var incompletePrepTasks: [PrepTask] {
        prepTasks.filter { !$0.isComplete }
    }

    var overduePrepTasks: [PrepTask] {
        prepTasks.filter(\.isOverdue)
    }

    var isDepartureSoon: Bool {
        let daysUntil = Calendar.current.dateComponents([.day], from: .now, to: departureDate).day ?? 0
        return daysUntil >= 0 && daysUntil <= 3
    }

    mutating func touch(by userName: String? = nil) {
        updatedAt = .now
        version += 1
        if let userName { lastModifiedBy = userName }
    }
}
