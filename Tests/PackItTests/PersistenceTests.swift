import Testing
import Foundation
@testable import PackIt

@Suite("Persistence")
struct PersistenceTests {
    private func makeTempPersistence() async -> (Persistence, URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = Persistence(baseURL: tempDir)
        return (persistence, tempDir)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("save and load template")
    func templateRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(
            name: "Beach Trip",
            items: [TemplateItem(name: "Sunscreen", category: "Toiletries", priority: .high)],
            contextTags: ["beach", "summer"]
        )

        try await persistence.saveTemplate(template)
        let loaded = try await persistence.loadTemplates()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Beach Trip")
        #expect(loaded.first?.items.count == 1)
        #expect(loaded.first?.contextTags == ["beach", "summer"])
    }

    @Test("delete template")
    func templateDelete() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(name: "Delete Me")
        try await persistence.saveTemplate(template)

        var loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 1)

        try await persistence.deleteTemplate(id: template.id)
        loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 0)
    }

    @Test("delete nonexistent template throws")
    func deleteNonexistent() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        await #expect(throws: PersistenceError.self) {
            try await persistence.deleteTemplate(id: UUID())
        }
    }

    @Test("save and load trip")
    func tripRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let trip = TripInstance(
            name: "Hawaii 2026",
            departureDate: Date.now,
            items: [TripItem(name: "Swimsuit", priority: .high)],
            todos: [TripTodo(text: "Book hotel")],
            scratchNotes: "Pack light",
            status: .planning
        )

        try await persistence.saveTrip(trip)
        let loaded = try await persistence.loadTrips()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Hawaii 2026")
        #expect(loaded.first?.items.count == 1)
        #expect(loaded.first?.todos.count == 1)
        #expect(loaded.first?.scratchNotes == "Pack light")
    }

    @Test("save and load tags")
    func tagsRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let tags = [
            ContextTag(name: "beach", color: "#00AAFF"),
            ContextTag(name: "winter"),
        ]

        try await persistence.saveTags(tags)
        let loaded = try await persistence.loadTags()

        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.name == "beach" })
        #expect(loaded.contains { $0.name == "winter" })
    }

    @Test("load tags from empty file returns empty array")
    func emptyTags() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let loaded = try await persistence.loadTags()
        #expect(loaded.isEmpty)
    }

    @Test("export and import trip")
    func exportImport() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let trip = TripInstance(
            name: "Export Test",
            items: [TripItem(name: "Test Item")],
            status: .active
        )

        let data = try await persistence.exportTrip(trip)
        let imported = try await persistence.importTrip(from: data)

        #expect(imported.name == "Export Test")
        #expect(imported.items.count == 1)
        #expect(imported.status == .active)
    }

    @Test("multiple templates stored independently")
    func multipleTemplates() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let t1 = PackingTemplate(name: "Template A", items: [TemplateItem(name: "Item A")])
        let t2 = PackingTemplate(name: "Template B", items: [TemplateItem(name: "Item B1"), TemplateItem(name: "Item B2")])

        try await persistence.saveTemplate(t1)
        try await persistence.saveTemplate(t2)

        let loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 2)

        let names = Set(loaded.map(\.name))
        #expect(names.contains("Template A"))
        #expect(names.contains("Template B"))
    }

    @Test("update overwrites existing file")
    func updateTemplate() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        var template = PackingTemplate(name: "Original")
        try await persistence.saveTemplate(template)

        template.name = "Updated"
        try await persistence.saveTemplate(template)

        let loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Updated")
    }
}
