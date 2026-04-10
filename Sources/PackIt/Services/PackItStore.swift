import SwiftUI

@Observable
@MainActor
final class PackItStore {
    var templates: [PackingTemplate] = []
    var trips: [TripInstance] = []
    var tags: [ContextTag] = []

    var searchQuery = ""
    var navigation: NavigationItem? = .templates {
        didSet {
            if let navigation {
                localConfig.lastNavigationKey = navigation.sectionKey
                localConfig.save()
            }
        }
    }
    var tripListCompact = false
    var tripDetailFullscreen = false
    var selectedTemplateID: UUID?
    var selectedTripID: UUID?
    var selectedTagID: UUID?
    var isLoading = false
    var error: String?
    var undoManager: UndoManager?
    var localConfig: LocalConfig
    var showEditItemsOnNextTrip = false

    var colorScheme: ColorScheme? {
        switch localConfig.appearance {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }

    // Sharing & conflict
    var conflicts: [Conflict] = []
    private var knownVersions: [UUID: Int] = [:]
    private var refreshTimer: Timer?

    private let persistence: Persistence
    private let notifications: NotificationService?
    private var searchTask: Task<Void, Never>?

    init(persistence: Persistence = .shared, notifications: NotificationService? = .shared) {
        let config = LocalConfig.load()
        self.localConfig = config
        self.persistence = persistence
        self.notifications = notifications

        // Configure shared path
        Task {
            if let sharedURL = config.resolvedSharedURL {
                await persistence.configureSharedPath(sharedURL)
            }
        }

        if config.launchView == .lastUsed,
           let restored = NavigationItem.from(sectionKey: config.lastNavigationKey) {
            self.navigation = restored
        }
    }

    // MARK: - Background Refresh

    func startBackgroundRefresh() {
        guard refreshTimer == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.silentReload()
            }
        }
    }

    func stopBackgroundRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func silentReload() {
        Task {
            do {
                let newTemplates = try await persistence.loadTemplates()
                let newTrips = try await persistence.loadTrips()
                detectConflicts(newTemplates: newTemplates, newTrips: newTrips)
                templates = newTemplates
                templates.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                trips = newTrips
                tags = try await persistence.loadTags()
                snapshotVersions()
                rebuildCaches()
            } catch {
                // Silently ignore — next poll will retry
            }
        }
    }

    private func snapshotVersions() {
        knownVersions.removeAll()
        for template in templates { knownVersions[template.id] = template.version }
        for trip in trips { knownVersions[trip.id] = trip.version }
    }

    private func detectConflicts(newTemplates: [PackingTemplate], newTrips: [TripInstance]) {
        let myName = localConfig.userName
        for template in newTemplates {
            if let known = knownVersions[template.id],
               template.version > known,
               template.lastModifiedBy != nil,
               template.lastModifiedBy != myName {
                if !conflicts.contains(where: { $0.entityID == template.id && $0.version == template.version }) {
                    conflicts.append(Conflict(
                        entityID: template.id,
                        entityName: template.name,
                        entityType: .template,
                        version: template.version,
                        modifiedBy: template.lastModifiedBy ?? "Unknown"
                    ))
                }
            }
        }
        for trip in newTrips {
            if let known = knownVersions[trip.id],
               trip.version > known,
               trip.lastModifiedBy != nil,
               trip.lastModifiedBy != myName {
                if !conflicts.contains(where: { $0.entityID == trip.id && $0.version == trip.version }) {
                    conflicts.append(Conflict(
                        entityID: trip.id,
                        entityName: trip.name,
                        entityType: .trip,
                        version: trip.version,
                        modifiedBy: trip.lastModifiedBy ?? "Unknown"
                    ))
                }
            }
        }
    }

    func dismissConflict(_ conflict: Conflict) {
        conflicts.removeAll { $0.id == conflict.id }
        knownVersions[conflict.entityID] = conflict.version
    }

    // MARK: - Sharing

    func isSharedTemplate(_ id: UUID) -> Bool {
        Task { await persistence.isShared(templateID: id) }
        // Synchronous check from cached state
        return templates.first(where: { $0.id == id }) != nil && _sharedTemplateIDs.contains(id)
    }

    func isSharedTrip(_ id: UUID) -> Bool {
        return _sharedTripIDs.contains(id)
    }

    private(set) var _sharedTemplateIDs: Set<UUID> = []
    private(set) var _sharedTripIDs: Set<UUID> = []

    func refreshSharedState() {
        Task {
            _sharedTemplateIDs.removeAll()
            _sharedTripIDs.removeAll()
            for template in templates {
                if await persistence.isShared(templateID: template.id) {
                    _sharedTemplateIDs.insert(template.id)
                }
            }
            for trip in trips {
                if await persistence.isShared(tripID: trip.id) {
                    _sharedTripIDs.insert(trip.id)
                }
            }
        }
    }

    func shareTemplate(id: UUID) {
        Task {
            do {
                try await persistence.shareTemplate(id: id)
                _sharedTemplateIDs.insert(id)
                loadAll()
            } catch {
                self.error = "Failed to share template: \(error.localizedDescription)"
            }
        }
    }

    func unshareTemplate(id: UUID) {
        Task {
            do {
                try await persistence.unshareTemplate(id: id)
                _sharedTemplateIDs.remove(id)
                loadAll()
            } catch {
                self.error = "Failed to unshare template: \(error.localizedDescription)"
            }
        }
    }

    func shareTrip(id: UUID) {
        Task {
            do {
                try await persistence.shareTrip(id: id)
                _sharedTripIDs.insert(id)
                loadAll()
            } catch {
                self.error = "Failed to share trip: \(error.localizedDescription)"
            }
        }
    }

    func unshareTrip(id: UUID) {
        Task {
            do {
                try await persistence.unshareTrip(id: id)
                _sharedTripIDs.remove(id)
                loadAll()
            } catch {
                self.error = "Failed to unshare trip: \(error.localizedDescription)"
            }
        }
    }

    func configureSharedPath(_ path: String) {
        localConfig.sharedDataPath = path
        localConfig.save()
        Task {
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            await persistence.configureSharedPath(url)
            loadAll()
        }
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
    private(set) var cachedPrepTaskCategories: [String] = []
    private(set) var cachedOwners: [String] = []

    var allItemNames: [String] { cachedItemNames }
    var allCategories: [String] { cachedCategories }
    var allPrepTaskCategories: [String] { cachedPrepTaskCategories }
    var allOwners: [String] { cachedOwners }

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
        var owners = Set<String>()
        var prepCats = Set<String>(["Home", "Supplies", "Travel Docs", "Pets", "Financial"])
        for template in templates {
            for item in template.items {
                names.insert(item.name)
                if let cat = item.category { cats.insert(cat) }
                if let owner = item.owner { owners.insert(owner) }
            }
            for task in template.prepTasks {
                if let cat = task.category { prepCats.insert(cat) }
            }
        }
        for trip in trips {
            for item in trip.items {
                names.insert(item.name)
                if let cat = item.category { cats.insert(cat) }
                if let owner = item.owner { owners.insert(owner) }
            }
            for task in trip.prepTasks {
                if let cat = task.category { prepCats.insert(cat) }
            }
        }
        cachedItemNames = names.sorted()
        cachedCategories = cats.sorted()
        cachedPrepTaskCategories = prepCats.sorted()
        cachedOwners = owners.sorted()
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
                snapshotVersions()
                refreshSharedState()
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
        updated.touch(by: localConfig.userName.isEmpty ? nil : localConfig.userName)
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

    /// Resolve all templates including linked/composite templates (deduped, no cycles).
    func resolveTemplates(ids: [UUID]) -> [PackingTemplate] {
        var resolved: [PackingTemplate] = []
        var seen = Set<UUID>()

        func walk(_ id: UUID) {
            guard !seen.contains(id) else { return }
            seen.insert(id)
            guard let template = templates.first(where: { $0.id == id }) else { return }
            // Walk linked templates first so their items come before the composite's own items
            for linkedID in template.linkedTemplateIDs {
                walk(linkedID)
            }
            resolved.append(template)
        }

        for id in ids { walk(id) }
        return resolved
    }

    func createTrip(name: String, icon: TripIcon = .suitcase, destination: TripDestination? = nil, departureDate: Date, returnDate: Date?, templateIDs: [UUID], selectedTags: [String]) -> TripInstance {
        let sourceTemplates = resolveTemplates(ids: templateIDs)
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

        // Build prep tasks from templates with same tag-filtering and dedup
        var prepTasks: [PrepTask] = []
        var seenTaskNames = Set<String>()
        for template in sourceTemplates {
            let matchingTasks: [PrepTaskTemplate]
            if selectedTags.isEmpty {
                matchingTasks = template.prepTasks
            } else {
                matchingTasks = template.prepTasks.filter { task in
                    task.contextTags.isEmpty || task.contextTags.contains(where: { selectedTags.contains($0) })
                }
            }
            for task in matchingTasks {
                let key = task.name.lowercased()
                guard !seenTaskNames.contains(key) else { continue }
                seenTaskNames.insert(key)
                prepTasks.append(PrepTask(from: task, departureDate: departureDate, returnDate: returnDate))
            }
        }

        // Build procedures from templates (dedup by name)
        var procedures: [Procedure] = []
        var seenProcNames = Set<String>()
        for template in sourceTemplates {
            for proc in template.procedures {
                let key = proc.name.lowercased()
                guard !seenProcNames.contains(key) else { continue }
                seenProcNames.insert(key)
                procedures.append(Procedure(from: proc))
            }
        }

        // Collect reference links from templates (dedup by URL)
        var refLinks: [ReferenceLink] = []
        var seenURLs = Set<String>()
        for template in sourceTemplates {
            for link in template.referenceLinks {
                let key = link.url.lowercased()
                guard !seenURLs.contains(key) else { continue }
                seenURLs.insert(key)
                refLinks.append(link)
            }
        }

        let trip = TripInstance(
            name: name,
            icon: icon,
            destination: destination,
            sourceTemplateIDs: templateIDs,
            departureDate: departureDate,
            returnDate: returnDate,
            items: items,
            prepTasks: prepTasks,
            procedures: procedures,
            referenceLinks: refLinks,
            status: .planning
        )

        showEditItemsOnNextTrip = true

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
        updated.touch(by: localConfig.userName.isEmpty ? nil : localConfig.userName)
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

    func removeItems(from tripID: UUID, itemIDs: Set<UUID>) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.items.removeAll { itemIDs.contains($0.id) }
        updateTrip(trip, actionName: "Remove Items")
    }

    func recategorizeItem(tripID: UUID, itemID: UUID, newCategory: String?) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.items.firstIndex(where: { $0.id == itemID }) else { return }
        trip.items[idx].category = newCategory
        updateTrip(trip, actionName: "Recategorize Item")
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

    // MARK: - Prep Tasks

    func addPrepTask(to tripID: UUID, name: String, category: String?, timing: PrepTaskTiming, notes: String?, departureDate: Date, returnDate: Date?) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let task = PrepTask(name: name, category: category, timing: timing, dueDate: timing.dueDate(departure: departureDate, returnDate: returnDate), notes: notes, isAdHoc: true)
        trip.prepTasks.append(task)
        updateTrip(trip, actionName: "Add Prep Task")
    }

    func togglePrepTask(tripID: UUID, taskID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.prepTasks.firstIndex(where: { $0.id == taskID }) else { return }
        trip.prepTasks[idx].isComplete.toggle()
        updateTrip(trip, actionName: "Toggle Prep Task")
    }

    func removePrepTask(from tripID: UUID, taskID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.prepTasks.removeAll { $0.id == taskID }
        updateTrip(trip, actionName: "Remove Prep Task")
    }

    // MARK: - Procedures

    func toggleProcedureStep(tripID: UUID, procedureID: UUID, stepID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }),
              let sIdx = trip.procedures[pIdx].steps.firstIndex(where: { $0.id == stepID }) else { return }
        trip.procedures[pIdx].steps[sIdx].isComplete.toggle()
        updateTrip(trip, actionName: "Toggle Step")
    }

    func addProcedureStep(tripID: UUID, procedureID: UUID, text: String, notes: String? = nil, atPosition: Int? = nil) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }) else { return }

        let newStep = ProcedureStep(text: text, notes: notes, sortOrder: 0)

        if let pos = atPosition, pos < trip.procedures[pIdx].steps.count {
            // Insert at specific position
            var sorted = trip.procedures[pIdx].steps.sorted(by: { $0.sortOrder < $1.sortOrder })
            sorted.insert(newStep, at: pos)
            // Renumber all
            for i in sorted.indices { sorted[i].sortOrder = i }
            trip.procedures[pIdx].steps = sorted
        } else {
            // Append at end
            var step = newStep
            step.sortOrder = trip.procedures[pIdx].steps.count
            trip.procedures[pIdx].steps.append(step)
        }

        updateTrip(trip, actionName: "Add Step")
    }

    func moveProcedureStep(tripID: UUID, procedureID: UUID, stepID: UUID, before targetID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }),
              let sourceIdx = trip.procedures[pIdx].steps.firstIndex(where: { $0.id == stepID }),
              let targetIdx = trip.procedures[pIdx].steps.firstIndex(where: { $0.id == targetID }),
              sourceIdx != targetIdx else { return }
        let step = trip.procedures[pIdx].steps.remove(at: sourceIdx)
        let newTarget = trip.procedures[pIdx].steps.firstIndex(where: { $0.id == targetID }) ?? trip.procedures[pIdx].steps.endIndex
        trip.procedures[pIdx].steps.insert(step, at: newTarget)
        for i in trip.procedures[pIdx].steps.indices {
            trip.procedures[pIdx].steps[i].sortOrder = i
        }
        updateTrip(trip, actionName: "Reorder Steps")
    }

    func updateProcedureStep(tripID: UUID, procedureID: UUID, stepID: UUID, text: String, notes: String?) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }),
              let sIdx = trip.procedures[pIdx].steps.firstIndex(where: { $0.id == stepID }) else { return }
        trip.procedures[pIdx].steps[sIdx].text = text
        trip.procedures[pIdx].steps[sIdx].notes = notes
        updateTrip(trip, actionName: "Edit Step")
    }

    func removeProcedureStep(tripID: UUID, procedureID: UUID, stepID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }) else { return }
        trip.procedures[pIdx].steps.removeAll { $0.id == stepID }
        // Re-number
        for i in trip.procedures[pIdx].steps.indices {
            trip.procedures[pIdx].steps[i].sortOrder = i
        }
        updateTrip(trip, actionName: "Remove Step")
    }

    func resetProcedure(tripID: UUID, procedureID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }) else { return }
        for i in trip.procedures[pIdx].steps.indices {
            trip.procedures[pIdx].steps[i].isComplete = false
        }
        updateTrip(trip, actionName: "Reset Procedure")
    }

    func removeProcedure(from tripID: UUID, procedureID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.procedures.removeAll { $0.id == procedureID }
        updateTrip(trip, actionName: "Remove Procedure")
    }

    func toggleProcedureCollapse(tripID: UUID, procedureID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let pIdx = trip.procedures.firstIndex(where: { $0.id == procedureID }) else { return }
        trip.procedures[pIdx].isCollapsed.toggle()
        updateTrip(trip, actionName: "Toggle Procedure")
    }

    // MARK: - Meal Plan

    func initMealPlan(tripID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }), trip.mealPlan == nil else { return }
        trip.mealPlan = MealPlan.generate(departure: trip.departureDate, returnDate: trip.returnDate)
        updateTrip(trip, actionName: "Create Meal Plan")
    }

    func updateMealSlot(tripID: UUID, dayID: UUID, mealType: MealType, items: [String]) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              var plan = trip.mealPlan,
              let dayIdx = plan.days.firstIndex(where: { $0.id == dayID }) else { return }
        plan.days[dayIdx].setSlot(mealType, items: items)
        trip.mealPlan = plan
        updateTrip(trip, actionName: "Update Meal")
    }

    func updateMealPrepNotes(tripID: UUID, notes: String) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              var plan = trip.mealPlan else { return }
        plan.prepNotes = notes
        trip.mealPlan = plan
        updateTrip(trip, actionName: "Update Meal Prep Notes")
    }

    // MARK: - Activities

    func addActivity(to tripID: UUID, text: String) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let activity = TripActivity(text: text, sortOrder: trip.activities.count)
        trip.activities.append(activity)
        updateTrip(trip, actionName: "Add Activity")
    }

    func updateActivity(tripID: UUID, activityID: UUID, text: String) {
        guard var trip = trips.first(where: { $0.id == tripID }),
              let idx = trip.activities.firstIndex(where: { $0.id == activityID }) else { return }
        trip.activities[idx].text = text
        updateTrip(trip, actionName: "Edit Activity")
    }

    func removeActivity(from tripID: UUID, activityID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.activities.removeAll { $0.id == activityID }
        updateTrip(trip, actionName: "Remove Activity")
    }

    // MARK: - Import Templates into Trip

    func importTemplates(into tripID: UUID, templateIDs: [UUID], selectedTags: [String]) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        let sourceTemplates = resolveTemplates(ids: templateIDs)
        let existingItemNames = Set(trip.items.map { $0.name.lowercased() })
        let existingTaskNames = Set(trip.prepTasks.map { $0.name.lowercased() })

        var newItems: [TripItem] = []
        var newTasks: [PrepTask] = []
        var seenItems = existingItemNames
        var seenTasks = existingTaskNames

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
                guard !seenItems.contains(key) else { continue }
                seenItems.insert(key)
                newItems.append(TripItem(from: item))
            }

            let matchingTasks: [PrepTaskTemplate]
            if selectedTags.isEmpty {
                matchingTasks = template.prepTasks
            } else {
                matchingTasks = template.prepTasks.filter { task in
                    task.contextTags.isEmpty || task.contextTags.contains(where: { selectedTags.contains($0) })
                }
            }
            for task in matchingTasks {
                let key = task.name.lowercased()
                guard !seenTasks.contains(key) else { continue }
                seenTasks.insert(key)
                newTasks.append(PrepTask(from: task, departureDate: trip.departureDate, returnDate: trip.returnDate))
            }
        }

        trip.items.append(contentsOf: newItems)
        trip.prepTasks.append(contentsOf: newTasks)
        if !templateIDs.isEmpty {
            trip.sourceTemplateIDs.append(contentsOf: templateIDs.filter { !trip.sourceTemplateIDs.contains($0) })
        }
        updateTrip(trip, actionName: "Import Templates")
    }

    // MARK: - Reference Links

    func addReferenceLink(to tripID: UUID, label: String, url: String, category: String?) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.referenceLinks.append(ReferenceLink(label: label, url: url, category: category))
        updateTrip(trip, actionName: "Add Link")
    }

    func removeReferenceLink(from tripID: UUID, linkID: UUID) {
        guard var trip = trips.first(where: { $0.id == tripID }) else { return }
        trip.referenceLinks.removeAll { $0.id == linkID }
        updateTrip(trip, actionName: "Remove Link")
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
