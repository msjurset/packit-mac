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

    public init(id: UUID = UUID(), items: [String] = []) {
        self.id = id
        self.items = items
    }

    public var isEmpty: Bool { items.isEmpty }
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

    public mutating func setSlot(_ type: MealType, items: [String]) {
        switch type {
        case .breakfast: breakfast.items = items
        case .lunch: lunch.items = items
        case .dinner: dinner.items = items
        case .snacks: snacks.items = items
        case .beverages: beverages.items = items
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
