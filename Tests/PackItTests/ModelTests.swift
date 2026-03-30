import Testing
import Foundation
@testable import PackIt

@Suite("Priority")
struct PriorityTests {
    @Test("comparable ordering")
    func ordering() {
        #expect(Priority.low < Priority.medium)
        #expect(Priority.medium < Priority.high)
        #expect(Priority.high < Priority.critical)
        #expect(!(Priority.critical < Priority.low))
    }

    @Test("label is capitalized")
    func label() {
        #expect(Priority.low.label == "Low")
        #expect(Priority.critical.label == "Critical")
    }
}

@Suite("ContextTag")
struct ContextTagTests {
    @Test("round-trip JSON encoding")
    func roundTrip() throws {
        let tag = ContextTag(name: "beach", color: "#00AAFF")
        let data = try JSONEncoder().encode(tag)
        let decoded = try JSONDecoder().decode(ContextTag.self, from: data)
        #expect(decoded.name == "beach")
        #expect(decoded.color == "#00AAFF")
        #expect(decoded.id == tag.id)
    }
}

@Suite("TemplateItem")
struct TemplateItemTests {
    @Test("round-trip JSON encoding")
    func roundTrip() throws {
        let item = TemplateItem(name: "Sunscreen", category: "Toiletries", contextTags: ["beach"], priority: .high, notes: "SPF 50+")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(TemplateItem.self, from: data)
        #expect(decoded.name == "Sunscreen")
        #expect(decoded.category == "Toiletries")
        #expect(decoded.contextTags == ["beach"])
        #expect(decoded.priority == .high)
        #expect(decoded.notes == "SPF 50+")
    }

    @Test("default values")
    func defaults() {
        let item = TemplateItem(name: "Test")
        #expect(item.category == nil)
        #expect(item.contextTags.isEmpty)
        #expect(item.priority == .medium)
        #expect(item.notes == nil)
    }
}

@Suite("PackingTemplate")
struct PackingTemplateTests {
    @Test("item count")
    func itemCount() {
        let template = PackingTemplate(
            name: "Beach",
            items: [
                TemplateItem(name: "Towel"),
                TemplateItem(name: "Sunscreen"),
            ]
        )
        #expect(template.itemCount == 2)
    }

    @Test("categories deduplication")
    func categories() {
        let template = PackingTemplate(
            name: "Test",
            items: [
                TemplateItem(name: "A", category: "Clothes"),
                TemplateItem(name: "B", category: "Toiletries"),
                TemplateItem(name: "C", category: "Clothes"),
            ]
        )
        #expect(template.categories.count == 2)
        #expect(template.categories.contains("Clothes"))
        #expect(template.categories.contains("Toiletries"))
    }

    @Test("round-trip encoding with ISO8601 dates")
    func roundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let template = PackingTemplate(name: "Test", items: [TemplateItem(name: "Item1")], contextTags: ["winter"])
        let data = try encoder.encode(template)
        let decoded = try decoder.decode(PackingTemplate.self, from: data)
        #expect(decoded.name == "Test")
        #expect(decoded.items.count == 1)
        #expect(decoded.contextTags == ["winter"])
    }
}

@Suite("TripItem")
struct TripItemTests {
    @Test("create from template item")
    func fromTemplate() {
        let templateItem = TemplateItem(name: "Passport", category: "Documents", priority: .critical, notes: "Check expiry")
        let tripItem = TripItem(from: templateItem)
        #expect(tripItem.name == "Passport")
        #expect(tripItem.category == "Documents")
        #expect(tripItem.priority == .critical)
        #expect(tripItem.notes == "Check expiry")
        #expect(tripItem.isPacked == false)
        #expect(tripItem.isAdHoc == false)
        #expect(tripItem.sourceTemplateItemID == templateItem.id)
        #expect(tripItem.id != templateItem.id)
    }

    @Test("overdue detection")
    func overdue() {
        var item = TripItem(name: "Test", dueDate: Date.now.addingTimeInterval(-86400))
        #expect(item.isOverdue == true)

        item.isPacked = true
        #expect(item.isOverdue == false)

        item.isPacked = false
        item.dueDate = Date.now.addingTimeInterval(86400)
        #expect(item.isOverdue == false)

        item.dueDate = nil
        #expect(item.isOverdue == false)
    }
}

@Suite("TripTodo")
struct TripTodoTests {
    @Test("overdue detection")
    func overdue() {
        var todo = TripTodo(text: "Book hotel", dueDate: Date.now.addingTimeInterval(-86400))
        #expect(todo.isOverdue == true)

        todo.isComplete = true
        #expect(todo.isOverdue == false)
    }
}

@Suite("TripInstance")
struct TripInstanceTests {
    @Test("progress calculation")
    func progress() {
        let trip = TripInstance(
            name: "Test",
            items: [
                TripItem(name: "A", isPacked: true),
                TripItem(name: "B", isPacked: false),
                TripItem(name: "C", isPacked: true),
                TripItem(name: "D", isPacked: false),
            ]
        )
        #expect(trip.packedCount == 2)
        #expect(trip.totalItems == 4)
        #expect(trip.progress == 0.5)
    }

    @Test("empty trip progress is zero")
    func emptyProgress() {
        let trip = TripInstance(name: "Empty")
        #expect(trip.progress == 0)
    }

    @Test("ad hoc items filtered")
    func adHocItems() {
        let trip = TripInstance(
            name: "Test",
            items: [
                TripItem(name: "A", isAdHoc: false),
                TripItem(name: "B", isAdHoc: true),
                TripItem(name: "C", isAdHoc: true),
            ]
        )
        #expect(trip.adHocItems.count == 2)
    }

    @Test("overdue high-priority items")
    func overdueItems() {
        let trip = TripInstance(
            name: "Test",
            items: [
                TripItem(name: "A", priority: .high, dueDate: Date.now.addingTimeInterval(-86400)),
                TripItem(name: "B", priority: .low, dueDate: Date.now.addingTimeInterval(-86400)),
                TripItem(name: "C", priority: .critical, dueDate: Date.now.addingTimeInterval(86400)),
                TripItem(name: "D", priority: .high, isPacked: true, dueDate: Date.now.addingTimeInterval(-86400)),
            ]
        )
        #expect(trip.overdueItems.count == 1)
        #expect(trip.overdueItems.first?.name == "A")
    }

    @Test("departure soon detection")
    func departureSoon() {
        var trip = TripInstance(name: "Test", departureDate: Date.now.addingTimeInterval(2 * 86400))
        #expect(trip.isDepartureSoon == true)

        trip.departureDate = Date.now.addingTimeInterval(10 * 86400)
        #expect(trip.isDepartureSoon == false)
    }
}
