import SwiftUI

@Observable
@MainActor
final class PackItStore {
    var templates: [PackingTemplate] = []
    var trips: [TripInstance] = []
    var tags: [ContextTag] = []

    var searchQuery = ""
    var navigation: NavigationItem? = .templates
    var selectedTemplateID: UUID?
    var selectedTripID: UUID?
    var selectedTagID: UUID?
    var isLoading = false
    var error: String?
    var undoManager: UndoManager?

    private let persistence: Persistence
    private let notifications: NotificationService?
    private var searchTask: Task<Void, Never>?

    init(persistence: Persistence = .shared, notifications: NotificationService? = .shared) {
        self.persistence = persistence
        self.notifications = notifications
    }

    private func registerUndo(_ name: String, handler: @escaping @MainActor (PackItStore) -> Void) {
        undoManager?.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                handler(store)
            }
        }
        undoManager?.setActionName(name)
    }

    var selectedTemplate: PackingTemplate? {
        guard let id = selectedTemplateID else { return nil }
        return templates.first { $0.id == id }
    }

    var selectedTrip: TripInstance? {
        guard let id = selectedTripID else { return nil }
        return trips.first { $0.id == id }
    }

    var selectedTag: ContextTag? {
        guard let id = selectedTagID else { return nil }
        return tags.first { $0.id == id }
    }

    var planningTrips: [TripInstance] {
        trips.filter { $0.status == .planning }.sorted { $0.departureDate < $1.departureDate }
    }

    var activeTrips: [TripInstance] {
        trips.filter { $0.status == .active }.sorted { $0.departureDate < $1.departureDate }
    }

    var completedTrips: [TripInstance] {
        trips.filter { $0.status == .completed }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var archivedTrips: [TripInstance] {
        trips.filter { $0.status == .archived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var allTagNames: [String] {
        Array(Set(tags.map(\.name))).sorted()
    }

    private(set) var cachedItemNames: [String] = []
    private(set) var cachedCategories: [String] = []

    var allItemNames: [String] { cachedItemNames }
    var allCategories: [String] { cachedCategories }

    func templateItem(named name: String) -> TemplateItem? {
        for template in templates {
            if let item = template.items.first(where: { $0.name == name }) {
                return item
            }
        }
        return nil
    }

    func rebuildCaches() {
        var names = Set<String>()
        var cats = Set<String>()
        for template in templates {
            for item in template.items {
                names.insert(item.name)
                if let cat = item.category { cats.insert(cat) }
            }
        }
        for trip in trips {
            for item in trip.items {
                names.insert(item.name)
                if let cat = item.category { cats.insert(cat) }
            }
        }
        cachedItemNames = names.sorted()
        cachedCategories = cats.sorted()
    }

    // MARK: - Loading

    func loadAll() {
        guard !isLoading else { return }
        Task {
            isLoading = true
            error = nil
            do {
                templates = try await persistence.loadTemplates()
                templates.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                trips = try await persistence.loadTrips()
                tags = try await persistence.loadTags()
                _ = await notifications?.requestPermission()
            } catch {
                self.error = error.localizedDescription
            }
            rebuildCaches()
            isLoading = false
        }
    }

    func debouncedRefresh() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            loadAll()
        }
    }

    // MARK: - Search

    var filteredTemplates: [PackingTemplate] {
        guard !searchQuery.isEmpty else { return templates }
        let q = searchQuery.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(q) ||
            template.contextTags.contains { $0.lowercased().contains(q) } ||
            template.items.contains { $0.name.lowercased().contains(q) }
        }
    }

    var filteredTrips: [TripInstance] {
        guard !searchQuery.isEmpty else { return trips }
        let q = searchQuery.lowercased()
        return trips.filter { trip in
            trip.name.lowercased().contains(q) ||
            trip.items.contains { $0.name.lowercased().contains(q) } ||
            trip.scratchNotes.lowercased().contains(q)
        }
    }

    // MARK: - Template CRUD

    func createTemplate(name: String, contextTags: [String]) {
        var template = PackingTemplate(name: name, contextTags: contextTags)
        template.touch()
        Task {
            do {
                try await persistence.saveTemplate(template)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func updateTemplate(_ template: PackingTemplate, actionName: String = "Edit Template") {
        if let previous = templates.first(where: { $0.id == template.id }) {
            registerUndo(actionName) { store in
                store.updateTemplate(previous, actionName: actionName)
            }
        }
        var updated = template
        updated.touch()
        Task {
            do {
                try await persistence.saveTemplate(updated)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func duplicateTemplate(id: UUID) {
        guard let source = templates.first(where: { $0.id == id }) else { return }
        var copy = PackingTemplate(
            name: "\(source.name) Copy",
            items: source.items.map { TemplateItem(name: $0.name, category: $0.category, contextTags: $0.contextTags, priority: $0.priority, notes: $0.notes, quantity: $0.quantity) },
            contextTags: source.contextTags
        )
        copy.touch()
        Task {
            do {
                try await persistence.saveTemplate(copy)
                loadAll()
                selectedTemplateID = copy.id
                navigation = .templateDetail(copy.id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteTemplate(id: UUID) {
        guard let template = templates.first(where: { $0.id == id }) else { return }
        registerUndo("Delete Template") { store in
            store.restoreTemplate(template)
        }
        Task {
            do {
                try await persistence.deleteTemplate(id: id)
                if selectedTemplateID == id { selectedTemplateID = nil }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func restoreTemplate(_ template: PackingTemplate) {
        registerUndo("Delete Template") { store in
            store.deleteTemplate(id: template.id)
        }
        Task {
            do {
                try await persistence.saveTemplate(template)
                loadAll()
                selectedTemplateID = template.id
                navigation = .templateDetail(template.id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Template Item Reordering

    func moveTemplateItem(in templateID: UUID, itemID: UUID, before targetID: UUID) {
        guard var template = templates.first(where: { $0.id == templateID }),
              let sourceIdx = template.items.firstIndex(where: { $0.id == itemID }),
              let targetIdx = template.items.firstIndex(where: { $0.id == targetID }),
              sourceIdx != targetIdx else { return }
        let sourceCategory = template.items[sourceIdx].category ?? "Uncategorized"
        let targetCategory = template.items[targetIdx].category ?? "Uncategorized"
        guard sourceCategory == targetCategory else { return }
        let item = template.items.remove(at: sourceIdx)
        let newTarget = template.items.firstIndex(where: { $0.id == targetID }) ?? template.items.endIndex
        template.items.insert(item, at: newTarget)
        updateTemplate(template, actionName: "Reorder Items")
    }

    // MARK: - Trip CRUD

    func createTrip(name: String, departureDate: Date, returnDate: Date?, templateIDs: [UUID], selectedTags: [String]) -> TripInstance {
        let sourceTemplates = templates.filter { templateIDs.contains($0.id) }
        var items: [TripItem] = []
        var seenNames = Set<String>()

        for template in sourceTemplates {
            let matchingItems: [TemplateItem]
            if selectedTags.isEmpty {
                matchingItems = template.items
            } else {
                matchingItems = template.items.filter { item in
                    item.contextTags.isEmpty || item.contextTags.contains(where: { selectedTags.contains($0) })
                }
            }
            for item in matchingItems {
                let key = item.name.lowercased()
                guard !seenNames.contains(key) else { continue }
                seenNames.insert(key)
                items.append(TripItem(from: item))
            }
        }

        let trip = TripInstance(
            name: name,
            sourceTemplateIDs: templateIDs,
            departureDate: departureDate,
            returnDate: returnDate,
            items: items,
            status: .planning
        )

        Task {
            do {
                try await persistence.saveTrip(trip)
                await notifications?.syncReminders(trip: trip)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
        return trip
    }

    func updateTrip(_ trip: TripInstance, actionName: String = "Edit Trip") {
        if let previous = trips.first(where: { $0.id == trip.id }) {
            registerUndo(actionName) { store in
                store.updateTrip(previous, actionName: actionName)
            }
        }
        var updated = trip
        updated.touch()
        Task {
            do {
                try await persistence.saveTrip(updated)
                await notifications?.syncReminders(trip: updated)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteTrip(id: UUID) {
        guard let trip = trips.first(where: { $0.id == id }) else { return }
        registerUndo("Delete Trip") { store in
            store.restoreTrip(trip)
        }
        Task {
            do {
                try await persistence.deleteTrip(id: id)
                await notifications?.cancelAllReminders(tripID: id)
                if selectedTripID == id { selectedTripID = nil }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func restoreTrip(_ trip: TripInstance) {
        registerUndo("Delete Trip") { store in
            store.deleteTrip(id: trip.id)
        }
        Task {
            do {
                try await persistence.saveTrip(trip)
                await notifications?.syncReminders(trip: trip)
                loadAll()
                selectedTripID = trip.id
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Trip Item Reordering

    func moveTripItem(in tripID: UUID, itemID: UUID, before targetID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let sourceIdx = trip.items.firstIndex(where: { $0.id == itemID }),
              let targetIdx = trip.items.firstIndex(where: { $0.id == targetID }),
              sourceIdx != targetIdx else { return }
        let sourceCategory = trip.items[sourceIdx].category ?? "Uncategorized"
        let targetCategory = trip.items[targetIdx].category ?? "Uncategorized"
        guard sourceCategory == targetCategory else { return }
        let item = trip.items.remove(at: sourceIdx)
        let newTarget = trip.items.firstIndex(where: { $0.id == targetID }) ?? trip.items.endIndex
        trip.items.insert(item, at: newTarget)
        updateTrip(trip, actionName: "Reorder Items")
    }

    // MARK: - Trip Item Operations

    func setAllPacked(tripID: UUID, category: String, packed: Bool) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        for i in trip.items.indices {
            if (trip.items[i].category ?? "Uncategorized") == category {
                trip.items[i].isPacked = packed
            }
        }
        updateTrip(trip, actionName: packed ? "Pack All in \(category)" : "Unpack All in \(category)")
    }

    func togglePacked(tripID: UUID, itemID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.items.firstIndex(where: { $0.id == itemID }) else { return }
        let wasPacked = trip.items[idx].isPacked
        trip.items[idx].isPacked.toggle()
        updateTrip(trip, actionName: wasPacked ? "Unpack Item" : "Pack Item")
    }

    func addAdHocItem(to tripID: UUID, name: String, category: String?, priority: Priority, quantity: Int = 1) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let item = TripItem(name: name, category: category, priority: priority, isAdHoc: true, quantity: quantity)
        trip.items.append(item)
        updateTrip(trip, actionName: "Add Item")
    }

    func removeItem(from tripID: UUID, itemID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.items.removeAll { $0.id == itemID }
        updateTrip(trip, actionName: "Remove Item")
    }

    // MARK: - Trip Todo Operations

    func addTodo(to tripID: UUID, text: String, dueDate: Date?, priority: Priority) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let todo = TripTodo(text: text, dueDate: dueDate, priority: priority)
        trip.todos.append(todo)
        updateTrip(trip, actionName: "Add TODO")
    }

    func toggleTodo(tripID: UUID, todoID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.todos.firstIndex(where: { $0.id == todoID }) else { return }
        trip.todos[idx].isComplete.toggle()
        updateTrip(trip, actionName: "Toggle TODO")
    }

    func removeTodo(from tripID: UUID, todoID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.todos.removeAll { $0.id == todoID }
        updateTrip(trip, actionName: "Remove TODO")
    }

    // MARK: - Promote / Merge

    func promoteItems(_ itemIDs: [UUID], from tripID: UUID, to templateID: UUID) {
        guard let trip = trips.first(where: { $0.id == tripID }),
              var template = templates.first(where: { $0.id == templateID }) else { return }

        let adHocItems = trip.items.filter { itemIDs.contains($0.id) && $0.isAdHoc }
        let existingNames = Set(template.items.map { $0.name.lowercased() })

        for item in adHocItems {
            guard !existingNames.contains(item.name.lowercased()) else { continue }
            let templateItem = TemplateItem(
                name: item.name,
                category: item.category,
                priority: item.priority,
                notes: item.notes,
                quantity: item.quantity
            )
            template.items.append(templateItem)
        }

        updateTemplate(template, actionName: "Merge Items")
    }

    // MARK: - Tag Management

    func addTag(name: String, color: String? = nil) {
        guard !tags.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        let previousTags = tags
        var updated = tags
        updated.append(ContextTag(name: name, color: color))
        registerUndo("Add Tag") { store in
            store.saveTags(previousTags)
        }
        saveTags(updated)
    }

    func removeTag(id: UUID) {
        guard let tag = tags.first(where: { $0.id == id }) else { return }
        let tagName = tag.name
        let previousTags = tags
        let previousTemplates = templates
        registerUndo("Remove Tag") { store in
            store.restoreTagsAndTemplates(tags: previousTags, templates: previousTemplates)
        }
        var updated = tags
        updated.removeAll { $0.id == id }
        Task {
            do {
                try await persistence.saveTags(updated)
                for var template in templates where template.contextTags.contains(tagName) || template.items.contains(where: { $0.contextTags.contains(tagName) }) {
                    template.contextTags.removeAll { $0 == tagName }
                    for i in template.items.indices {
                        template.items[i].contextTags.removeAll { $0 == tagName }
                    }
                    try await persistence.saveTemplate(template)
                }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func saveTags(_ updated: [ContextTag]) {
        Task {
            do {
                try await persistence.saveTags(updated)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func renameTag(id: UUID, newName: String) {
        guard let idx = tags.firstIndex(where: { $0.id == id }) else { return }
        let oldName = tags[idx].name
        let previousTags = tags
        let previousTemplates = templates
        registerUndo("Rename Tag") { store in
            store.restoreTagsAndTemplates(tags: previousTags, templates: previousTemplates)
        }
        var updated = tags
        updated[idx].name = newName
        Task {
            do {
                try await persistence.saveTags(updated)
                for var template in templates where template.contextTags.contains(oldName) {
                    template.contextTags = template.contextTags.map { $0 == oldName ? newName : $0 }
                    for i in template.items.indices {
                        template.items[i].contextTags = template.items[i].contextTags.map { $0 == oldName ? newName : $0 }
                    }
                    try await persistence.saveTemplate(template)
                }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func restoreTagsAndTemplates(tags: [ContextTag], templates: [PackingTemplate]) {
        let currentTags = self.tags
        let currentTemplates = self.templates
        registerUndo("Rename Tag") { store in
            store.restoreTagsAndTemplates(tags: currentTags, templates: currentTemplates)
        }
        Task {
            do {
                try await persistence.saveTags(tags)
                for template in templates {
                    try await persistence.saveTemplate(template)
                }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Export / Import

    func exportTrip(_ trip: TripInstance) async throws -> Data {
        try await persistence.exportTrip(trip)
    }

    func importTrip(from url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                var trip = try await persistence.importTrip(from: data)
                trip.id = UUID()  // New ID to avoid collisions
                try await persistence.saveTrip(trip)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func exportTemplate(_ template: PackingTemplate) async throws -> Data {
        try await persistence.exportTemplate(template)
    }

    func importTemplate(from url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                var template = try await persistence.importTemplate(from: data)
                template.id = UUID()
                try await persistence.saveTemplate(template)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Config

    func loadConfig() async throws -> AppConfig {
        try await persistence.loadConfig()
    }

    func saveConfig(_ config: AppConfig) async throws {
        try await persistence.saveConfig(config)
    }

    func printTrip(_ trip: TripInstance) {
        Task {
            let config = (try? await persistence.loadConfig()) ?? AppConfig()
            PrintService.print(trip: trip, config: config)
        }
    }
}
