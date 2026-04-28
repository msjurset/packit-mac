import Foundation

enum PrepTaskTiming: String, Codable, CaseIterable, Comparable, Sendable {
    case early
    case weeksBefore
    case weekBefore
    case daysBefore
    case dayOf
    case onReturn

    var label: String {
        switch self {
        case .early: "Early"
        case .weeksBefore: "2 Weeks Before"
        case .weekBefore: "1 Week Before"
        case .daysBefore: "Day Before"
        case .dayOf: "Day Of"
        case .onReturn: "On Return"
        }
    }

    var shortLabel: String {
        switch self {
        case .early: "early"
        case .weeksBefore: "2wk before"
        case .weekBefore: "1wk before"
        case .daysBefore: "day before"
        case .dayOf: "day of"
        case .onReturn: "on return"
        }
    }

    var icon: String { icon(for: .plane) }

    /// Travel-mode-aware icon. Only `.dayOf` and `.onReturn` actually vary;
    /// the rest are calendar-based and identical across modes.
    func icon(for travelMode: TravelMode) -> String {
        switch self {
        case .early: "calendar.badge.exclamationmark"
        case .weeksBefore: "calendar.badge.clock"
        case .weekBefore: "calendar"
        case .daysBefore: "calendar.day.timeline.left"
        case .dayOf: travelMode.departureSymbol
        case .onReturn: travelMode.arrivalSymbol
        }
    }

    private var sortIndex: Int {
        switch self {
        case .early: 0
        case .weeksBefore: 1
        case .weekBefore: 2
        case .daysBefore: 3
        case .dayOf: 4
        case .onReturn: 5
        }
    }

    static func < (lhs: PrepTaskTiming, rhs: PrepTaskTiming) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

    func dueDate(departure: Date, returnDate: Date?) -> Date {
        switch self {
        case .early:
            Calendar.current.date(byAdding: .day, value: -21, to: departure)!
        case .weeksBefore:
            Calendar.current.date(byAdding: .day, value: -14, to: departure)!
        case .weekBefore:
            Calendar.current.date(byAdding: .day, value: -7, to: departure)!
        case .daysBefore:
            Calendar.current.date(byAdding: .day, value: -1, to: departure)!
        case .dayOf:
            departure
        case .onReturn:
            returnDate ?? Calendar.current.date(byAdding: .day, value: 7, to: departure)!
        }
    }
}

struct PrepTaskTemplate: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var category: String?
    var timing: PrepTaskTiming
    var contextTags: [String]
    var notes: String?

    init(id: UUID = UUID(), name: String, category: String? = nil, timing: PrepTaskTiming = .daysBefore, contextTags: [String] = [], notes: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.timing = timing
        self.contextTags = contextTags
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        timing = try container.decodeIfPresent(PrepTaskTiming.self, forKey: .timing) ?? .daysBefore
        contextTags = try container.decodeIfPresent([String].self, forKey: .contextTags) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}
