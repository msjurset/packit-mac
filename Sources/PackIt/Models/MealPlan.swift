import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snacks
    case beverages

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snacks: "Snacks"
        case .beverages: "Beverages"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snacks: "carrot.fill"
        case .beverages: "cup.and.saucer.fill"
        }
    }
}

struct MealSlot: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var items: [String]

    init(id: UUID = UUID(), items: [String] = []) {
        self.id = id
        self.items = items
    }

    var isEmpty: Bool { items.isEmpty }
    var display: String { items.joined(separator: ", ") }
}

struct MealDay: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var breakfast: MealSlot
    var lunch: MealSlot
    var dinner: MealSlot
    var snacks: MealSlot
    var beverages: MealSlot

    init(id: UUID = UUID(), date: Date) {
        self.id = id
        self.date = date
        self.breakfast = MealSlot()
        self.lunch = MealSlot()
        self.dinner = MealSlot()
        self.snacks = MealSlot()
        self.beverages = MealSlot()
    }

    var dayLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    var dateLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    func slot(for type: MealType) -> MealSlot {
        switch type {
        case .breakfast: breakfast
        case .lunch: lunch
        case .dinner: dinner
        case .snacks: snacks
        case .beverages: beverages
        }
    }

    mutating func setSlot(_ type: MealType, items: [String]) {
        switch type {
        case .breakfast: breakfast.items = items
        case .lunch: lunch.items = items
        case .dinner: dinner.items = items
        case .snacks: snacks.items = items
        case .beverages: beverages.items = items
        }
    }
}

struct MealPlan: Codable, Hashable, Sendable {
    var days: [MealDay]
    var prepNotes: String

    init(days: [MealDay] = [], prepNotes: String = "") {
        self.days = days
        self.prepNotes = prepNotes
    }

    /// Generate days from trip departure to return.
    static func generate(departure: Date, returnDate: Date?) -> MealPlan {
        let end = returnDate ?? Calendar.current.date(byAdding: .day, value: 3, to: departure)!
        let dayCount = max(1, (Calendar.current.dateComponents([.day], from: departure, to: end).day ?? 0) + 1)
        let days = (0..<dayCount).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: departure)!
            return MealDay(date: date)
        }
        return MealPlan(days: days)
    }

    /// All unique food items across all days and meal types.
    var allFoodItems: [String] {
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
