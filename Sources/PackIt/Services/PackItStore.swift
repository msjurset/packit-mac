import SwiftUI

@Observable
@MainActor
final class PackItStore {
    var templates: [PackingTemplate] = []
    var trips: [TripInstance] = []
    var tags: [ContextTag] = []

    var searchQuery = ""
    var sidebarSelection: SidebarItem? = .templates
    var selectedTemplateID: UUID?
    var selectedTripID: UUID?
    var isLoading = false
    var error: String?

    private let persistence: Persistence
    private let notifications: NotificationService
    private var searchTask: Task<Void, Never>?

    init(persistence: Persistence = .shared, notifications: NotificationService = .shared) {
        self.persistence = persistence
        self.notifications = notifications
    }

    var selectedTemplate: PackingTemplate? {
        guard let id = selectedTemplateID else { return nil }
        return templates.first { $0.id == id }
    }

    var selectedTrip: TripInstance? {
        guard let id = selectedTripID else { return nil }
        return trips.first { $0.id == id }
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
                _ = await notifications.requestPermission()
            } catch {
                self.error = error.localizedDescription
            }
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

    func updateTemplate(_ template: PackingTemplate) {
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

    func deleteTemplate(id: UUID) {
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
                await notifications.syncReminders(trip: trip)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
        return trip
    }

    func updateTrip(_ trip: TripInstance) {
        var updated = trip
        updated.touch()
        Task {
            do {
                try await persistence.saveTrip(updated)
                await notifications.syncReminders(trip: updated)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteTrip(id: UUID) {
        Task {
            do {
                try await persistence.deleteTrip(id: id)
                await notifications.cancelAllReminders(tripID: id)
                if selectedTripID == id { selectedTripID = nil }
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Trip Item Operations

    func togglePacked(tripID: UUID, itemID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.items.firstIndex(where: { $0.id == itemID }) else { return }
        trip.items[idx].isPacked.toggle()
        updateTrip(trip)
    }

    func addAdHocItem(to tripID: UUID, name: String, category: String?, priority: Priority) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let item = TripItem(name: name, category: category, priority: priority, isAdHoc: true)
        trip.items.append(item)
        updateTrip(trip)
    }

    func removeItem(from tripID: UUID, itemID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.items.removeAll { $0.id == itemID }
        updateTrip(trip)
    }

    // MARK: - Trip Todo Operations

    func addTodo(to tripID: UUID, text: String, dueDate: Date?, priority: Priority) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let todo = TripTodo(text: text, dueDate: dueDate, priority: priority)
        trip.todos.append(todo)
        updateTrip(trip)
    }

    func toggleTodo(tripID: UUID, todoID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.todos.firstIndex(where: { $0.id == todoID }) else { return }
        trip.todos[idx].isComplete.toggle()
        updateTrip(trip)
    }

    func removeTodo(from tripID: UUID, todoID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.todos.removeAll { $0.id == todoID }
        updateTrip(trip)
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
                notes: item.notes
            )
            template.items.append(templateItem)
        }

        updateTemplate(template)
    }

    // MARK: - Tag Management

    func addTag(name: String, color: String? = nil) {
        guard !tags.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        var updated = tags
        updated.append(ContextTag(name: name, color: color))
        Task {
            do {
                try await persistence.saveTags(updated)
                loadAll()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func removeTag(id: UUID) {
        var updated = tags
        updated.removeAll { $0.id == id }
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
        var updated = tags
        updated[idx].name = newName
        Task {
            do {
                try await persistence.saveTags(updated)
                // Update templates that reference the old tag name
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
}
