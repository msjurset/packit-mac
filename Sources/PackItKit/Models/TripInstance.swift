import Foundation

public enum TripStatus: String, Codable, CaseIterable, Sendable {
    case planning
    case active
    case completed
    case archived

    public var label: String {
        rawValue.capitalized
    }

    public var icon: String {
        switch self {
        case .planning: return "pencil.and.list.clipboard"
        case .active: return "suitcase.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }
}

public struct TripInstance: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var icon: TripIcon
    public var destination: TripDestination?
    public var sourceTemplateIDs: [UUID]
    public var departureDate: Date
    public var returnDate: Date?
    public var items: [TripItem]
    public var prepTasks: [PrepTask]
    public var todos: [TripTodo]
    public var activities: [TripActivity]
    public var procedures: [Procedure]
    public var mealPlan: MealPlan?
    public var referenceLinks: [ReferenceLink]
    public var scratchNotes: String
    public var status: TripStatus
    public var version: Int
    public var lastModifiedBy: String?
    public var createdBy: String?
    public var rank: Int
    public var members: [String]
    public var travelMode: TravelMode
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), name: String, icon: TripIcon = .suitcase, destination: TripDestination? = nil, sourceTemplateIDs: [UUID] = [], departureDate: Date = .now, returnDate: Date? = nil, items: [TripItem] = [], prepTasks: [PrepTask] = [], todos: [TripTodo] = [], activities: [TripActivity] = [], procedures: [Procedure] = [], mealPlan: MealPlan? = nil, referenceLinks: [ReferenceLink] = [], version: Int = 1, lastModifiedBy: String? = nil, createdBy: String? = nil, rank: Int = Int.max, members: [String] = [], travelMode: TravelMode = .plane, scratchNotes: String = "", status: TripStatus = .planning, createdAt: Date = .now, updatedAt: Date = .now) {
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
        self.members = members
        self.travelMode = travelMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
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
        members = try container.decodeIfPresent([String].self, forKey: .members) ?? []
        travelMode = try container.decodeIfPresent(TravelMode.self, forKey: .travelMode) ?? .plane
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    public var packedCount: Int { items.filter(\.isPacked).count }
    public var totalItems: Int { items.count }
    public var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(packedCount) / Double(totalItems)
    }

    public var adHocItems: [TripItem] {
        items.filter(\.isAdHoc)
    }

    public var overdueItems: [TripItem] {
        items.filter { $0.isOverdue && $0.priority >= .high }
    }

    public var incompleteTodos: [TripTodo] {
        todos.filter { !$0.isComplete }
    }

    public var incompletePrepTasks: [PrepTask] {
        prepTasks.filter { !$0.isComplete }
    }

    public var overduePrepTasks: [PrepTask] {
        prepTasks.filter(\.isOverdue)
    }

    public var isDepartureSoon: Bool {
        let daysUntil = Calendar.current.dateComponents([.day], from: .now, to: departureDate).day ?? 0
        return daysUntil >= 0 && daysUntil <= 3
    }

    public mutating func touch(by userName: String? = nil) {
        updatedAt = .now
        version += 1
        if let userName { lastModifiedBy = userName }
    }
}
