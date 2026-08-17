import Foundation

public enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snacks
    case beverages

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snacks: "Snacks"
        case .beverages: "Beverages"
        }
    }

    public var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snacks: "carrot.fill"
        case .beverages: "cup.and.saucer.fill"
        }
    }
}

public struct MealSlot: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var items: [String]
    public var icons: [String]

    public init(id: UUID = UUID(), items: [String] = [], icons: [String] = []) {
        self.id = id
        self.items = items
        self.icons = icons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        items = try container.decode([String].self, forKey: .items)
        icons = try container.decodeIfPresent([String].self, forKey: .icons) ?? []
    }

    public var isEmpty: Bool { items.isEmpty && icons.isEmpty }
    public var display: String { items.joined(separator: ", ") }
}

public struct MealDay: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var breakfast: MealSlot
    public var lunch: MealSlot
    public var dinner: MealSlot
    public var snacks: MealSlot
    public var beverages: MealSlot

    public init(id: UUID = UUID(), date: Date) {
        self.id = id
        self.date = date
        self.breakfast = MealSlot()
        self.lunch = MealSlot()
        self.dinner = MealSlot()
        self.snacks = MealSlot()
        self.beverages = MealSlot()
    }

    public var dayLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    public var dateLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    public func slot(for type: MealType) -> MealSlot {
        switch type {
        case .breakfast: breakfast
        case .lunch: lunch
        case .dinner: dinner
        case .snacks: snacks
        case .beverages: beverages
        }
    }

    public mutating func setSlot(_ type: MealType, items: [String], icons: [String] = []) {
        switch type {
        case .breakfast:
            breakfast.items = items
            breakfast.icons = icons
        case .lunch:
            lunch.items = items
            lunch.icons = icons
        case .dinner:
            dinner.items = items
            dinner.icons = icons
        case .snacks:
            snacks.items = items
            snacks.icons = icons
        case .beverages:
            beverages.items = items
            beverages.icons = icons
        }
    }
}

public struct MealPlan: Codable, Hashable, Sendable {
    public var days: [MealDay]
    public var prepNotes: String

    public init(days: [MealDay] = [], prepNotes: String = "") {
        self.days = days
        self.prepNotes = prepNotes
    }

    /// Generate days from trip departure to return.
    public static func generate(departure: Date, returnDate: Date?) -> MealPlan {
        let end = returnDate ?? Calendar.current.date(byAdding: .day, value: 3, to: departure)!
        let dayCount = max(1, (Calendar.current.dateComponents([.day], from: departure, to: end).day ?? 0) + 1)
        let days = (0..<dayCount).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: departure)!
            return MealDay(date: date)
        }
        return MealPlan(days: days)
    }

    /// Update days to match a new date range, preserving existing meal data.
    public mutating func syncDates(departure: Date, returnDate: Date?) {
        let end = returnDate ?? Calendar.current.date(byAdding: .day, value: 3, to: departure)!
        let dayCount = max(1, (Calendar.current.dateComponents([.day], from: departure, to: end).day ?? 0) + 1)

        var newDays: [MealDay] = []
        for offset in 0..<dayCount {
            let targetDate = Calendar.current.date(byAdding: .day, value: offset, to: departure)!
            if offset < days.count {
                var day = days[offset]
                day.date = targetDate
                newDays.append(day)
            } else {
                newDays.append(MealDay(date: targetDate))
            }
        }
        self.days = newDays
    }

    /// All unique food items across all days and meal types.
    public var allFoodItems: [String] {
        var items = Set<String>()
        for day in days {
            for type in MealType.allCases {
                for item in day.slot(for: type).items {
                    let trimmed = item.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { items.insert(trimmed) }
                }
            }
        }
        return items.sorted()
    }
}
