import Testing
import PackItKit
import Foundation
@testable import PackIt

@Suite("PackItStore Computed Properties")
struct StoreComputedTests {
    @MainActor
    private func makeStore() -> PackItStore {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return PackItStore(persistence: Persistence(baseURL: tempDir), notifications: nil)
    }

    // MARK: - allItemNames

    @Test("allItemNames collects from templates and trips, deduplicates, sorts")
    @MainActor
    func allItemNamesFromBothSources() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Beach", items: [
                TemplateItem(name: "Sunscreen"),
                TemplateItem(name: "Towel"),
            ]),
        ]
        store.trips = [
            TripInstance(name: "Hawaii", items: [
                TripItem(name: "Swimsuit"),
                TripItem(name: "Towel"),
            ]),
        ]
        store.rebuildCaches()
        #expect(store.allItemNames == ["Sunscreen", "Swimsuit", "Towel"])
    }

    @Test("allItemNames is empty when no data")
    @MainActor
    func allItemNamesEmpty() {
        let store = makeStore()
        #expect(store.allItemNames.isEmpty)
    }

    @Test("allItemNames is sorted alphabetically")
    @MainActor
    func allItemNamesSorted() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Test", items: [
                TemplateItem(name: "Zebra"),
                TemplateItem(name: "Apple"),
                TemplateItem(name: "Mango"),
            ]),
        ]
        store.rebuildCaches()
        #expect(store.allItemNames == ["Apple", "Mango", "Zebra"])
    }

    // MARK: - templateItem(named:)

    @Test("templateItem finds item by name")
    @MainActor
    func templateItemFound() {
        let store = makeStore()
        let item = TemplateItem(name: "Passport", category: "Documents", priority: .critical)
        store.templates = [
            PackingTemplate(name: "Travel", items: [item]),
        ]
        let found = store.templateItem(named: "Passport")
        #expect(found?.name == "Passport")
        #expect(found?.category == "Documents")
        #expect(found?.priority == .critical)
    }

    @Test("templateItem returns nil for unknown name")
    @MainActor
    func templateItemNotFound() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Travel", items: [TemplateItem(name: "Passport")]),
        ]
        #expect(store.templateItem(named: "Nonexistent") == nil)
    }

    @Test("templateItem returns first match across templates")
    @MainActor
    func templateItemFirstMatch() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Beach", items: [TemplateItem(name: "Sunscreen", category: "Toiletries")]),
            PackingTemplate(name: "Camping", items: [TemplateItem(name: "Sunscreen", category: "Skin")]),
        ]
        #expect(store.templateItem(named: "Sunscreen")?.category == "Toiletries")
    }

    // MARK: - allCategories

    @Test("allCategories deduplicates across templates and trips")
    @MainActor
    func allCategoriesDeduplicates() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Test", items: [
                TemplateItem(name: "A", category: "Clothes"),
                TemplateItem(name: "B", category: "Toiletries"),
            ]),
        ]
        store.trips = [
            TripInstance(name: "Trip", items: [
                TripItem(name: "C", category: "Electronics"),
                TripItem(name: "D", category: "Clothes"),
            ]),
        ]
        store.rebuildCaches()
        #expect(store.allCategories == ["Clothes", "Electronics", "Toiletries"])
    }

    @Test("allCategories ignores nil categories")
    @MainActor
    func allCategoriesIgnoresNil() {
        let store = makeStore()
        store.templates = [
            PackingTemplate(name: "Test", items: [
                TemplateItem(name: "A"),
                TemplateItem(name: "B", category: "Clothes"),
            ]),
        ]
        store.rebuildCaches()
        #expect(store.allCategories == ["Clothes"])
    }
}

@Suite("Tag Cascade via Persistence")
struct TagCascadeTests {
    private func makeTempPersistence() -> (Persistence, URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return (Persistence(baseURL: tempDir), tempDir)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("removing tag cleans up template contextTags")
    func removeTagFromTemplateContextTags() async throws {
        let (persistence, tempDir) = makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(
            name: "Beach Trip",
            items: [TemplateItem(name: "Towel", contextTags: ["beach", "summer"])],
            contextTags: ["beach", "tropical"]
        )
        try await persistence.saveTemplate(template)

        // Simulate cascade: remove "beach" from template and items
        var updated = template
        updated.contextTags.removeAll { $0 == "beach" }
        for i in updated.items.indices {
            updated.items[i].contextTags.removeAll { $0 == "beach" }
        }
        try await persistence.saveTemplate(updated)

        let loaded = try await persistence.loadTemplates()
        #expect(loaded.first?.contextTags == ["tropical"])
        #expect(loaded.first?.items.first?.contextTags == ["summer"])
    }

    @Test("removing tag leaves unrelated templates unchanged")
    func removeTagLeavesUnrelatedTemplates() async throws {
        let (persistence, tempDir) = makeTempPersistence()
        defer { cleanup(tempDir) }

        let t1 = PackingTemplate(name: "Beach", contextTags: ["beach", "summer"])
        let t2 = PackingTemplate(name: "Winter", contextTags: ["winter", "cold"])
        try await persistence.saveTemplate(t1)
        try await persistence.saveTemplate(t2)

        // Cascade remove "beach" only from t1
        var updated = t1
        updated.contextTags.removeAll { $0 == "beach" }
        try await persistence.saveTemplate(updated)

        let loaded = try await persistence.loadTemplates()
        let winter = loaded.first { $0.name == "Winter" }
        #expect(winter?.contextTags == ["winter", "cold"])
    }
}
