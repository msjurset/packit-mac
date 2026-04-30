import SwiftUI
import PackItKit
import AppKit

/// Drag payload prefix for category-reorder drags. Item drops are bare UUIDs,
/// which can't collide with this prefix — single dropDestination handles both.
private let categoryDragPrefix = "__pkcat__:"

struct TripDetailView: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    let trip: TripInstance
    @State private var activeSheet: TripSheet?
    @State private var pendingReminders = 0
    @State private var showInspector = true
    @State private var newTodoText = ""
    @State private var viewMode: TripViewMode = .packing
    @State private var prepDragStartWidth: CGFloat?
    @State private var editingItem: TripItem?

    // memberFilter and prepWidth live on the store so they survive view re-creation
    // (notably when toggling fullscreen, which re-mounts TripDetailView).
    private var memberFilter: Set<String> {
        store.tripUI(trip.id).memberFilter ?? Set(trip.members)
    }

    private var prepWidth: CGFloat {
        store.tripUI(trip.id).prepWidth
    }
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var lastClickedItemID: UUID?
    @State private var showSearch = false
    @State private var searchQuery = ""
    @State private var currentMatchIndex = 0
    @State private var keyMonitor: Any?
    @State private var searchFocused: Bool = false
    @State private var searchSuggestionsDismissed = false
    @State private var selectedSuggestionIndex: Int = -1
    @State private var searchRefocusToken: Int = 0
    @State private var isCyclingSearchSuggestion = false
    @State private var searchOutsideClickMonitor: Any? = nil
    @State private var scrollProxy: ScrollViewProxy?
    @State private var searchFieldFrame: CGRect = .zero
    @State private var draggingCategory: String?
    @State private var dropTargetCategory: String?

    enum TripViewMode: String, CaseIterable {
        case packing = "Packing"
        case meals = "Meals"
        case procedures = "Procedures"
    }

    enum TripSheet: Identifiable {
        case edit
        case addItem
        case merge
        case export
        case printSettings
        case addPrepTask
        case editItems
        case reviewItems
        case importTemplate

        var id: String { String(describing: self) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pinned trip header + view mode toggle
            VStack(spacing: 6) {
                tripHeader
                    .padding(.horizontal)
                    .padding(.top, 10)

                HStack(alignment: .top) {
                    Picker("View", selection: $viewMode) {
                        ForEach(TripViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 280)
                    Spacer()
                    if showSearch && viewMode == .packing {
                        searchField
                            .onGeometryChange(for: CGRect.self) { geo in
                                geo.frame(in: .global)
                            } action: { newFrame in
                                searchFieldFrame = newFrame
                            }
                            .background(
                                AnchoredSuggestionPopup(
                                    isVisible: .constant(isSearchDropdownVisible),
                                    anchorFrame: searchFieldFrame,
                                    width: max(searchFieldFrame.width, 280),
                                    height: searchDropdownHeight,
                                    gap: 4,
                                    horizontalAlignment: .trailing
                                ) {
                                    searchDropdownContent
                                        .environment(\.colorScheme, colorScheme)
                                }
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
                .animation(.easeInOut(duration: 0.15), value: showSearch)
            }
            .background(.background)

            // Subtle gradient separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.secondary.opacity(0.08), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 4)

            if viewMode == .packing {
                // Prep tasks (left) + Packing list (right) as siblings
                HStack(alignment: .top, spacing: 0) {
                    if !trip.prepTasks.isEmpty {
                        prepTaskTimeline
                            .frame(width: prepWidth)
                        prepResizer
                    }

                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 20) {
                                if !trip.overdueItems.isEmpty {
                                    overdueSection
                                        .padding(.horizontal)
                                }

                                packingSection
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .onAppear { scrollProxy = proxy }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if !selectedItemIDs.isEmpty {
                            bulkActionBar
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.18), value: selectedItemIDs.isEmpty)
                }
            } else if viewMode == .meals {
                MealPlanView(trip: trip)
            } else {
                ProcedureChecklistView(trip: trip)
            }
        }
        .onPreferenceChange(SearchFieldFramePreferenceKey.self) { frame in
            searchFieldFrame = frame
        }
        .onChange(of: searchFocused) { _, focused in
            // Re-focusing the field (e.g. user clicks back in) clears the
            // dismissal so suggestions return as they keep typing.
            if focused {
                searchSuggestionsDismissed = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .packitOpenTripSearch)) { _ in
            // Edit > Find… (Cmd-F): force-resign any focused field, then open.
            if let window = NSApp.keyWindow, window.firstResponder is NSTextView {
                window.makeFirstResponder(nil)
            }
            if !showSearch { openSearch() } else { searchSuggestionsDismissed = false }
        }
        .onChange(of: isSearchDropdownVisible) { _, visible in
            if visible {
                installSearchOutsideClickMonitor()
            } else {
                removeSearchOutsideClickMonitor()
            }
        }
        .accessibilityIdentifier("tripDetail")
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Section("Status") {
                        statusMenuItems
                    }
                    Section {
                        Button { activeSheet = .importTemplate } label: {
                            Label("Import Template...", systemImage: "arrow.down.doc")
                        }
                        if !trip.adHocItems.isEmpty {
                            Button { activeSheet = .merge } label: {
                                Label("Merge to Template...", systemImage: "arrow.up.doc")
                            }
                        }
                        Button { store.duplicateTrip(id: trip.id) } label: {
                            Label("Duplicate Trip", systemImage: "doc.on.doc")
                        }
                        Button { activeSheet = .export } label: {
                            Label("Export...", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }

                Button { activeSheet = .printSettings } label: {
                    Label("Print", systemImage: "printer")
                }
                .help("Print packing list")

                Button { activeSheet = .edit } label: {
                    Label("Edit Trip", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.tripDetailFullscreen.toggle()
                    }
                } label: {
                    Image(systemName: store.tripDetailFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(.secondary)
                }
                .help(store.tripDetailFullscreen ? "Exit fullscreen" : "Fullscreen")
            }

            ToolbarItem(placement: .automatic) {
                Button { showInspector.toggle() } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                        .foregroundStyle(showInspector ? .packitTeal : .secondary)
                }
                .help("Toggle TODOs & Notes")
            }
        }
        .inspector(isPresented: $showInspector) {
            TripInspectorView(trip: trip, activeSheet: $activeSheet, pendingReminders: pendingReminders)
                .inspectorColumnWidth(min: 250, ideal: 300, max: 380)
        }
        .sheet(item: $editingItem) { item in
            EditTripItemSheet(tripID: trip.id, originalItem: item)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                TripEditorSheet(trip: trip)
            case .addItem:
                AddTripItemSheet(tripID: trip.id)
            case .merge:
                MergeToTemplateSheet(trip: trip)
            case .export:
                ExportSheet(trip: trip)
            case .printSettings:
                PrintSettingsSheet(trip: trip)
            case .addPrepTask:
                AddPrepTaskSheet(tripID: trip.id, departureDate: trip.departureDate, returnDate: trip.returnDate)
            case .editItems:
                TripItemListEditor(tripID: trip.id)
            case .reviewItems:
                TripItemListEditor(tripID: trip.id, isReview: true)
            case .importTemplate:
                ImportTemplateSheet(tripID: trip.id)
            }
        }
        .task {
            pendingReminders = await NotificationService.shared.pendingCount(for: trip.id)
        }
        .onAppear {
            if store.showEditItemsOnNextTrip {
                store.showEditItemsOnNextTrip = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeSheet = .reviewItems
                }
            }
            if store.tripUI(trip.id).memberFilter == nil {
                store.setTripMemberFilter(Set(trip.members), for: trip.id)
            }
            installSearchKeyMonitor()
        }
        .onDisappear { removeSearchKeyMonitor() }
        .onChange(of: trip.members) { _, newMembers in
            // Drop members no longer present; auto-include any newly-added members.
            let updated = memberFilter.intersection(Set(newMembers)).union(Set(newMembers))
            store.setTripMemberFilter(updated, for: trip.id)
        }
        .onChange(of: searchQuery) { _, _ in
            currentMatchIndex = 0
            // Don't reset suggestion selection when the change came from
            // Tab/arrow cycling (otherwise cycling always returns to top).
            if !isCyclingSearchSuggestion {
                selectedSuggestionIndex = -1
                searchSuggestionsDismissed = false
                cycleAnchorSuggestions = nil
            }
            isCyclingSearchSuggestion = false
            scrollToCurrentMatch()
        }
    }

    // MARK: - Header

    private var tripHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    TripIconView(icon: trip.icon, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(trip.name)
                                .font(.title3.bold())
                            if store.isReceivedShare(tripID: trip.id) {
                                SharedBadge(author: trip.createdBy)
                            } else if store._sharedTripIDs.contains(trip.id) {
                                SharingOutBadge()
                            }
                        }
                        Text(trip.status.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        TravelHeaderIcon(mode: trip.travelMode, direction: .departure)
                        Text(trip.departureDate.formatted(date: .long, time: .omitted))
                    }
                    if let ret = trip.returnDate {
                        HStack(spacing: 5) {
                            TravelHeaderIcon(mode: trip.travelMode, direction: .arrival)
                            Text(ret.formatted(date: .long, time: .omitted))
                        }
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if trip.isDepartureSoon && trip.status == .active {
                    Label("Departure is soon!", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            Spacer()
            progressRing
        }
    }

    private var progressRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: trip.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: trip.progress)
                Text("\(Int(trip.progress * 100))%")
                    .font(.caption2.bold().monospacedDigit())
            }
            .frame(width: 52, height: 52)
            Text("\(trip.packedCount)/\(trip.totalItems)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var progressColor: Color {
        if trip.progress >= 1.0 { return .packitGreen }
        if trip.progress >= 0.5 { return .packitTeal }
        return .orange
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Needs Attention", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.packitRed)

            ForEach(trip.overdueItems) { item in
                HStack(spacing: 10) {
                    Button {
                        store.togglePacked(tripID: trip.id, itemID: item.id)
                    } label: {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isPacked ? .packitGreen : .packitRed)
                    }
                    .buttonStyle(.plain)

                    Text(item.name)
                        .font(.callout.bold())
                    Spacer()
                    if let due = item.dueDate {
                        Text("Due " + due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.packitRed)
                    }
                }
                .padding(10)
                .background(.packitRed.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Packing Section

    private var visiblePackingItems: [TripItem] {
        guard !trip.members.isEmpty else { return trip.items }
        return trip.items.filter { item in
            guard let owner = item.owner else { return true } // shared, always visible
            return memberFilter.contains(owner)
        }
    }

    private var showOwnerSuffix: Bool {
        memberFilter.count > 1
    }

    private var orderedCategoryKeys: [String] {
        let grouped = Dictionary(grouping: visiblePackingItems, by: { $0.category ?? "Uncategorized" })
        return store.orderedCategoryNames(Set(grouped.keys))
    }

    private var orderedVisibleItems: [TripItem] {
        let grouped = Dictionary(grouping: visiblePackingItems, by: { $0.category ?? "Uncategorized" })
        return orderedCategoryKeys.flatMap { grouped[$0] ?? [] }
    }

    private var packingSection: some View {
        let grouped = Dictionary(grouping: visiblePackingItems, by: { $0.category ?? "Uncategorized" })
        let sortedKeys = orderedCategoryKeys
        let ordered = orderedVisibleItems
        let sortMode = store.localConfig.resolvedCategorySortMode

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Packing List")
                    .font(.headline)
                Spacer()
                Button {
                    store.setCategorySortMode(sortMode == .name ? .manual : .name)
                } label: {
                    HStack(spacing: 3) {
                        Text(sortMode == .manual ? "Manual" : "Name")
                            .font(.caption)
                        Image(systemName: sortMode == .manual ? "line.3.horizontal" : "textformat.abc")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Category sort: click to switch (\(sortMode == .manual ? "Manual" : "Name"))")

                Button { activeSheet = .editItems } label: {
                    Label("Edit List", systemImage: "pencil.line")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button { activeSheet = .addItem } label: {
                    Label("Add Item", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.packitTeal)
            }

            if trip.members.count > 1 {
                memberFilterBar
            }

            ForEach(Array(sortedKeys.enumerated()), id: \.element) { index, category in
                CategorySection(
                    category: category,
                    items: grouped[category] ?? [],
                    tripID: trip.id,
                    isAlternate: index.isMultiple(of: 2),
                    showOwnerSuffix: showOwnerSuffix,
                    selectedItemIDs: selectedItemIDs,
                    searchMatchIDs: searchMatchSet,
                    currentSearchMatchID: currentMatchID,
                    isReorderable: sortMode == .manual,
                    isDragging: draggingCategory == category,
                    isDropTarget: dropTargetCategory == category,
                    onCategoryDragStart: { draggingCategory = category },
                    onCategoryDragEnd: {
                        draggingCategory = nil
                        dropTargetCategory = nil
                    },
                    onCategoryDropTargetChanged: { isTargeted in
                        if isTargeted {
                            dropTargetCategory = category
                        } else if dropTargetCategory == category {
                            dropTargetCategory = nil
                        }
                    },
                    onEdit: { item in editingItem = item },
                    onSelect: { item, modifiers in
                        handleItemClick(item: item, modifiers: modifiers, ordered: ordered)
                    },
                    onBulkSetOwner: { applyBulkOwner($0) },
                    onBulkDuplicate: { applyBulkDuplicate($0) },
                    onBulkRemove: { applyBulkRemove() }
                )
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                let mods = NSEvent.modifierFlags
                if !mods.contains(.command) && !mods.contains(.shift) && !selectedItemIDs.isEmpty {
                    clearSelection()
                }
            }
        )
    }

    private func handleItemClick(item: TripItem, modifiers: EventModifiers, ordered: [TripItem]) {
        if modifiers.contains(.shift), let anchorID = lastClickedItemID,
           let from = ordered.firstIndex(where: { $0.id == anchorID }),
           let to = ordered.firstIndex(where: { $0.id == item.id }) {
            let range = from <= to ? from...to : to...from
            for i in range {
                selectedItemIDs.insert(ordered[i].id)
            }
            lastClickedItemID = item.id
        } else if modifiers.contains(.command) {
            if selectedItemIDs.contains(item.id) {
                selectedItemIDs.remove(item.id)
            } else {
                selectedItemIDs.insert(item.id)
            }
            lastClickedItemID = item.id
        } else {
            // Plain click clears selection.
            clearSelection()
        }
    }

    @ViewBuilder
    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.rectangle.stack.fill")
                .foregroundStyle(.packitTeal)
            Text("\(selectedItemIDs.count) selected")
                .font(.callout.weight(.medium))

            Spacer()

            if !trip.members.isEmpty {
                Menu {
                    Button { applyBulkOwner(nil) } label: { Text("Shared (everyone)") }
                    ForEach(trip.members, id: \.self) { m in
                        Button { applyBulkOwner(m) } label: { Text(m) }
                    }
                } label: {
                    Label("Owner", systemImage: "person.crop.circle")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Menu {
                    Button { applyBulkDuplicate(nil) } label: { Text("Shared") }
                    ForEach(trip.members, id: \.self) { m in
                        Button { applyBulkDuplicate(m) } label: { Text(m) }
                    }
                } label: {
                    Label("Duplicate For", systemImage: "plus.square.on.square")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Button {
                applyBulkRemove()
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(.caption)
                    .foregroundStyle(.packitRed)
            }
            .buttonStyle(.plain)

            Button {
                clearSelection()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear selection (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.packitTeal.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func clearSelection() {
        selectedItemIDs.removeAll()
        lastClickedItemID = nil
    }

    // MARK: - Prep column resizer

    @ViewBuilder
    private var prepResizer: some View {
        // Visual: 1pt divider — minimal gap.
        // Hit area: 10pt-wide overlay that doesn't consume layout space.
        Divider()
            .overlay {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 10)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                if prepDragStartWidth == nil {
                                    prepDragStartWidth = prepWidth
                                }
                                let proposed = (prepDragStartWidth ?? prepWidth) + value.translation.width
                                store.setTripPrepWidth(max(160, min(500, proposed)), for: trip.id)
                            }
                            .onEnded { _ in prepDragStartWidth = nil }
                    )
            }
    }

    // MARK: - Search

    private var searchMatchIDs: [UUID] {
        let raw = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return [] }
        let tokens = parseSearchTokens(raw)
        return orderedVisibleItems.compactMap { item in
            tokens.allSatisfy { $0.matches(item) } ? item.id : nil
        }
    }

    private struct SearchToken {
        enum Field { case any, name, category, owner, notes, priority, packed }
        let field: Field
        let needle: String

        func matches(_ item: TripItem) -> Bool {
            switch field {
            case .any:
                let hay = [item.name, item.category ?? "", item.notes ?? "", item.owner ?? ""]
                    .joined(separator: " ")
                    .lowercased()
                return hay.contains(needle)
            case .name:     return item.name.lowercased().contains(needle)
            case .category: return (item.category ?? "").lowercased().contains(needle)
            case .owner:    return (item.owner ?? "").lowercased().contains(needle)
            case .notes:    return (item.notes ?? "").lowercased().contains(needle)
            case .priority:
                let label = item.priority.label.lowercased()
                let raw = item.priority.rawValue.lowercased()
                return label.contains(needle) || raw.contains(needle)
            case .packed:
                let truthy = ["yes", "y", "true", "1", "packed"]
                let falsy = ["no", "n", "false", "0", "unpacked"]
                if truthy.contains(needle) { return item.isPacked }
                if falsy.contains(needle) { return !item.isPacked }
                return false
            }
        }
    }

    private func parseSearchTokens(_ raw: String) -> [SearchToken] {
        var tokens: [SearchToken] = []
        for chunk in raw.split(whereSeparator: \.isWhitespace) {
            var s = String(chunk)
            if let colon = s.firstIndex(of: ":") {
                let key = s[..<colon].lowercased()
                var val = String(s[s.index(after: colon)...])
                if val.hasPrefix("\"") { val.removeFirst(); if val.hasSuffix("\"") { val.removeLast() } }
                let field: SearchToken.Field?
                switch key {
                case "name", "n":            field = .name
                case "category", "cat", "c": field = .category
                case "owner", "o":           field = .owner
                case "notes", "note":        field = .notes
                case "priority", "pri":      field = .priority
                case "packed":               field = .packed
                default:                     field = nil
                }
                if let field, !val.isEmpty {
                    tokens.append(SearchToken(field: field, needle: val.lowercased()))
                    continue
                }
            }
            if s.hasPrefix("\"") { s.removeFirst(); if s.hasSuffix("\"") { s.removeLast() } }
            if !s.isEmpty {
                tokens.append(SearchToken(field: .any, needle: s.lowercased()))
            }
        }
        return tokens
    }

    private var searchMatchSet: Set<UUID> { Set(searchMatchIDs) }

    private var currentMatchID: UUID? {
        guard !searchMatchIDs.isEmpty else { return nil }
        let idx = max(0, min(currentMatchIndex, searchMatchIDs.count - 1))
        return searchMatchIDs[idx]
    }

    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TokenizedSearchField(
                text: $searchQuery,
                placeholder: "Find in list…  (try category:Bath)",
                isFocused: $searchFocused,
                autoFocus: true,
                refocusToken: searchRefocusToken,
                onAdvance: { forward in cycleSuggestion(forward: forward) },
                onSubmit: { handleSearchSubmit() },
                onCancel: { handleSearchCancel() }
            )
            .frame(width: 220, height: 18)
            // Fixed-width counter slot prevents the field from re-laying out
            // (and the dropdown anchor from jumping) as matches/digits change.
            Group {
                if !searchMatchIDs.isEmpty {
                    Text("\(currentMatchIndex + 1)/\(searchMatchIDs.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else if !searchQuery.isEmpty {
                    Text("0")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                } else {
                    Text(" ").font(.caption2.monospacedDigit())
                }
            }
            .frame(width: 48, alignment: .trailing)
            Button { advanceMatch(by: -1) } label: {
                Image(systemName: "chevron.up")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(searchMatchIDs.isEmpty)
            .help("Previous match")
            Button { advanceMatch(by: 1) } label: {
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(searchMatchIDs.isEmpty)
            .help("Next match")
            Button { dismissSearch() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Close search")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var isSearchDropdownVisible: Bool {
        showSearch && !searchSuggestionsDismissed && !searchSuggestions.isEmpty
    }

    private func installSearchOutsideClickMonitor() {
        guard searchOutsideClickMonitor == nil else { return }
        searchOutsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            // Defer the dismissal so suggestion-row clicks still get to fire
            // their button action (which runs synchronously on the same event
            // loop tick before this async block).
            DispatchQueue.main.async {
                searchSuggestionsDismissed = true
                selectedSuggestionIndex = -1
                cycleAnchorSuggestions = nil
            }
            return event
        }
    }

    private func removeSearchOutsideClickMonitor() {
        if let m = searchOutsideClickMonitor {
            NSEvent.removeMonitor(m)
            searchOutsideClickMonitor = nil
        }
    }

    private var searchDropdownHeight: CGFloat {
        min(CGFloat(searchSuggestions.count) * 28 + 8, 260)
    }

    @ViewBuilder
    private var searchDropdownContent: some View {
        let bg: Color = colorScheme == .dark
            ? Color(red: 0.16, green: 0.16, blue: 0.18)
            : Color(red: 0.98, green: 0.98, blue: 0.98)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(searchSuggestions.enumerated()), id: \.offset) { index, suggestion in
                    Button {
                        acceptSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(index == selectedSuggestionIndex ? Color.packitTeal.opacity(0.25) : .clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
            .padding(.vertical, 4)
        }
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 0.5))
    }

    // MARK: - Search suggestions

    private static let searchFieldKeys: [String] = [
        "category:", "owner:", "name:", "priority:", "packed:", "notes:"
    ]

    private var searchActiveWord: (start: String.Index, value: String) {
        if let lastWS = searchQuery.lastIndex(where: { $0.isWhitespace }) {
            let start = searchQuery.index(after: lastWS)
            return (start, String(searchQuery[start...]))
        }
        return (searchQuery.startIndex, searchQuery)
    }

    private var searchSuggestions: [String] {
        // While a cycle is active (anchor non-nil), keep showing the anchored
        // list so the dropdown doesn't shrink to only the currently-previewed
        // item between Tab presses.
        if let anchored = cycleAnchorSuggestions {
            return anchored
        }
        return computeSuggestions(for: searchActiveWord.value)
    }

    @State private var cycleAnchorSuggestions: [String]? = nil

    private func computeSuggestions(for active: String) -> [String] {
        let lowerActive = active.lowercased()

        if let colonIdx = active.firstIndex(of: ":") {
            let key = String(active[..<colonIdx]).lowercased()
            let valueQuery = String(active[active.index(after: colonIdx)...]).lowercased()
            // Values use contains-style matching (search semantics).
            return suggestionValues(forFieldKey: key)
                .filter { valueQuery.isEmpty || $0.lowercased().contains(valueQuery) }
                .prefix(20)
                .map { "\(key):\($0)" }
        }

        // Field keys keep prefix matching — they're a small fixed set, prefix is what
        // people expect when the cursor is at the start of a token.
        if lowerActive.isEmpty {
            return Self.searchFieldKeys
        }
        return Self.searchFieldKeys.filter { $0.hasPrefix(lowerActive) }
    }

    private func suggestionValues(forFieldKey key: String) -> [String] {
        switch key {
        case "category", "cat", "c":
            let used = Set(trip.items.compactMap { $0.category })
            return used.sorted()
        case "owner", "o":
            return trip.members
        case "name", "n":
            return Array(Set(trip.items.map(\.name))).sorted()
        case "priority", "pri":
            return ["low", "medium", "high", "critical"]
        case "packed":
            return ["yes", "no"]
        case "notes", "note":
            return []   // free-form
        default:
            return []
        }
    }

    private func cycleSuggestion(forward: Bool) {
        // Snapshot suggestions on first cycle press so the list stays stable
        // even as the field's text changes during preview.
        if cycleAnchorSuggestions == nil {
            cycleAnchorSuggestions = computeSuggestions(for: searchActiveWord.value)
        }
        guard let list = cycleAnchorSuggestions, !list.isEmpty else { return }
        searchSuggestionsDismissed = false
        if forward {
            selectedSuggestionIndex = (selectedSuggestionIndex + 1) % list.count
        } else {
            selectedSuggestionIndex = (selectedSuggestionIndex - 1 + list.count) % list.count
        }
        let suggestion = list[selectedSuggestionIndex]
        isCyclingSearchSuggestion = true
        replaceActiveWord(with: suggestion, addTrailingSpace: false)
    }

    private func handleSearchSubmit() {
        // If a suggestion is currently selected, accepting Enter commits it
        // (already in the field via Tab/arrow preview). Add a trailing space
        // ONLY for value completions; key completions (ending in ":") expect
        // the user to keep typing the value directly.
        if selectedSuggestionIndex >= 0 && !searchSuggestionsDismissed {
            let endsWithKey = searchQuery.hasSuffix(":")
            if !endsWithKey && !searchQuery.hasSuffix(" ") {
                searchQuery += " "
            }
            selectedSuggestionIndex = -1
            cycleAnchorSuggestions = nil
            // Value commit: dismiss until the user types or Tabs again.
            // Key commit: keep open — the values list should pop immediately.
            if !endsWithKey {
                searchSuggestionsDismissed = true
            }
            return
        }
        // Else, advance to the next match (existing behavior).
        advanceMatch(by: 1)
    }

    private func handleSearchCancel() {
        if !searchSuggestionsDismissed && !searchSuggestions.isEmpty {
            // Dismiss suggestions, keep field open.
            searchSuggestionsDismissed = true
            selectedSuggestionIndex = -1
        } else {
            dismissSearch()
        }
    }

    private func acceptSuggestion(_ suggestion: String) {
        let isValue = !suggestion.hasSuffix(":")
        replaceActiveWord(with: suggestion, addTrailingSpace: isValue)
        selectedSuggestionIndex = -1
        cycleAnchorSuggestions = nil
        if isValue {
            searchSuggestionsDismissed = true
        }
        // Click on a suggestion row briefly steals first-responder; restore it.
        searchRefocusToken &+= 1
    }

    private func replaceActiveWord(with value: String, addTrailingSpace: Bool) {
        let start = searchActiveWord.start
        var newQuery = String(searchQuery[..<start]) + value
        if addTrailingSpace { newQuery += " " }
        searchQuery = newQuery
    }

    private func openSearch() {
        showSearch = true
        DispatchQueue.main.async { searchFocused = true }
    }

    private func dismissSearch() {
        showSearch = false
        searchQuery = ""
        currentMatchIndex = 0
        searchFocused = false
    }

    private func advanceMatch(by delta: Int) {
        guard !searchMatchIDs.isEmpty else { return }
        let n = searchMatchIDs.count
        currentMatchIndex = ((currentMatchIndex + delta) % n + n) % n
        scrollToCurrentMatch()
    }

    private func scrollToCurrentMatch() {
        guard let id = currentMatchID, let proxy = scrollProxy else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(id, anchor: .center)
        }
    }

    private func installSearchKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleSearchKey(event) ? nil : event
        }
    }

    private func removeSearchKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }

    private func handleSearchKey(_ event: NSEvent) -> Bool {
        let textViewFocused = event.window?.firstResponder is NSTextView
        let chars = event.charactersIgnoringModifiers ?? ""
        let mods = event.modifierFlags
        let hasNonShiftModifier = mods.intersection([.command, .control, .option]).isEmpty == false

        // ⌘F — universal "open search" shortcut. Force-resigns whatever field has
        // focus (notes, todos, activities, etc.) and opens search. Use this when
        // you can't get out of another field with click-outside.
        if chars.lowercased() == "f" && mods.contains(.command) && !mods.contains(.shift) && !mods.contains(.option) && !mods.contains(.control) {
            if textViewFocused { event.window?.makeFirstResponder(nil) }
            if !showSearch { openSearch() } else { searchSuggestionsDismissed = false }
            return true
        }

        // "/" toggles search — only when no text field has focus, so notes/todos/
        // activities can still contain a "/" character.
        if chars == "/" && !textViewFocused && !hasNonShiftModifier {
            if showSearch { dismissSearch() } else { openSearch() }
            return true
        }

        // Escape always dismisses search.
        if event.keyCode == 53, showSearch {
            dismissSearch()
            return true
        }

        // n / N / space → next match (only when search is open and field unfocused).
        if showSearch && !textViewFocused && !searchMatchIDs.isEmpty && !hasNonShiftModifier {
            if chars.lowercased() == "n" || chars == " " {
                advanceMatch(by: 1)
                return true
            }
        }

        return false
    }

    private func applyBulkOwner(_ owner: String?) {
        let ids = selectedItemIDs
        guard !ids.isEmpty else { return }
        store.bulkSetOwner(in: trip.id, itemIDs: ids, owner: owner)
        clearSelection()
    }

    private func applyBulkDuplicate(_ owner: String?) {
        let ids = selectedItemIDs
        guard !ids.isEmpty else { return }
        store.bulkDuplicate(in: trip.id, itemIDs: ids, newOwner: owner)
        clearSelection()
    }

    private func applyBulkRemove() {
        let ids = selectedItemIDs
        guard !ids.isEmpty else { return }
        store.removeItems(from: trip.id, itemIDs: ids)
        clearSelection()
    }

    @ViewBuilder
    private var memberFilterBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .help("Filter the list by member. Items owned by an unchecked member are hidden. Shared items (no owner) are always shown.")
            ForEach(trip.members, id: \.self) { member in
                let included = memberFilter.contains(member)
                Button {
                    var f = memberFilter
                    if included { f.remove(member) } else { f.insert(member) }
                    store.setTripMemberFilter(f, for: trip.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: included ? "checkmark.square.fill" : "square")
                            .foregroundStyle(included ? Color.packitTeal : Color.secondary)
                        Text(member)
                            .foregroundStyle(included ? .primary : .secondary)
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(included
                      ? "Hide \(member)'s items from this list"
                      : "Show \(member)'s items in this list")
            }
            Spacer()
            Text("Shared items always shown")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Prep Task Timeline

    private var prepTaskTimeline: some View {
        let grouped = Dictionary(grouping: trip.prepTasks, by: \.timing)
        let timingsWithTasks = PrepTaskTiming.allCases.filter { grouped[$0] != nil && !grouped[$0]!.isEmpty }

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Prep")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { activeSheet = .editItems } label: {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit prep tasks")
                    Button { activeSheet = .addPrepTask } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.packitTeal)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Timeline
                ForEach(Array(timingsWithTasks.enumerated()), id: \.element) { index, timing in
                    let tasks = grouped[timing] ?? []
                    let isLast = index == timingsWithTasks.count - 1

                    HStack(alignment: .top, spacing: 0) {
                        // Timeline node (line is drawn as background behind all nodes)
                        VStack(spacing: 0) {
                            // Space above first node, or line from previous
                            Rectangle()
                                .fill(index > 0 ? Color.packitTeal.opacity(0.25) : .clear)
                                .frame(width: 2, height: index > 0 ? 6 : 4)

                            // Node
                            ZStack {
                                Circle()
                                    .fill(.packitTeal.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Circle()
                                    .strokeBorder(.packitTeal.opacity(0.35), lineWidth: 1.2)
                                    .frame(width: 24, height: 24)
                                Image(systemName: timing.icon(for: trip.travelMode))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.packitTeal)
                            }

                            // Continuous line to next node with midpoint chevron
                            if !isLast {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(.packitTeal.opacity(0.25))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                    Image(systemName: "chevron.compact.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.packitTeal.opacity(0.35))
                                    Rectangle()
                                        .fill(.packitTeal.opacity(0.25))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                        }
                        .frame(width: 28)
                        .padding(.leading, 8)

                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            // Timing header
                            HStack(spacing: 0) {
                                Text(timing.label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.packitTeal)
                                Spacer()
                                Text(tasks.first?.dueDate.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }

                            // Tasks
                            ForEach(tasks) { task in
                                HStack(spacing: 5) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            store.togglePrepTask(tripID: trip.id, taskID: task.id)
                                        }
                                    } label: {
                                        Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                                            .font(.caption2)
                                            .foregroundStyle(task.isComplete ? .packitGreen : task.isOverdue ? .packitRed : .secondary)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                    .buttonStyle(.plain)

                                    Text(task.name)
                                        .font(.system(size: 11))
                                        .strikethrough(task.isComplete)
                                        .foregroundStyle(task.isComplete ? .tertiary : .primary)
                                        .lineLimit(1)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.removePrepTask(from: trip.id, taskID: task.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 10)
                        .padding(.vertical, 4)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .background(.secondary.opacity(0.02))
    }

    // MARK: - Status Menu Items

    @ViewBuilder
    private var statusMenuItems: some View {
        ForEach(TripStatus.allCases, id: \.self) { status in
            if status != trip.status {
                Button {
                    var updated = trip
                    updated.status = status
                    store.updateTrip(updated)
                } label: {
                    Label("Mark as \(status.label)", systemImage: status.icon)
                }
            }
        }
    }
}

// MARK: - Category Section

struct CategorySection: View {
    @Environment(PackItStore.self) private var store
    let category: String
    let items: [TripItem]
    let tripID: UUID
    var isAlternate: Bool = false
    var showOwnerSuffix: Bool = false
    var selectedItemIDs: Set<UUID> = []
    var searchMatchIDs: Set<UUID> = []
    var currentSearchMatchID: UUID?
    /// In manual sort mode, the header gets a drag handle and accepts
    /// other-category drops to reorder the list. In name mode it's hidden
    /// and only item drops are accepted.
    var isReorderable: Bool = false
    var isDragging: Bool = false
    var isDropTarget: Bool = false
    var onCategoryDragStart: () -> Void = {}
    var onCategoryDragEnd: () -> Void = {}
    var onCategoryDropTargetChanged: (Bool) -> Void = { _ in }
    var onEdit: (TripItem) -> Void = { _ in }
    var onSelect: (TripItem, EventModifiers) -> Void = { _, _ in }
    var onBulkSetOwner: (String?) -> Void = { _ in }
    var onBulkDuplicate: (String?) -> Void = { _ in }
    var onBulkRemove: () -> Void = {}

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isHeaderDropTargeted = false
    @State private var isRenameFocused: Bool = false
    @State private var showIconPicker = false

    private var packedCount: Int { items.filter(\.isPacked).count }
    private var allPacked: Bool { !items.isEmpty && packedCount == items.count }
    private let columns = [GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 4, alignment: .top)]
    private var categoryForStore: String? { category == "Uncategorized" ? nil : category }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        isRenaming = false
        guard !trimmed.isEmpty, trimmed != category, category != "Uncategorized" else { return }
        // Global rename so the picklist, settings, and other trips update too.
        store.renameCategoryGlobally(from: category, to: trimmed)
    }

    private var canReorder: Bool { isReorderable && category != "Uncategorized" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryDropStrip
            sectionBody
                .opacity(isDragging ? 0.35 : 1.0)
        }
        .background(isAlternate ? Color.secondary.opacity(0.04) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.15), value: isDropTarget)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }

    /// Thin drop zone above each section that catches category-reorder drags.
    /// When targeted, renders a teal capsule line as an insertion mark.
    @ViewBuilder
    private var categoryDropStrip: some View {
        let active = canReorder
        if active {
            ZStack {
                if isDropTarget {
                    Capsule()
                        .fill(Color.packitTeal)
                        .frame(height: 3)
                        .padding(.horizontal, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isDropTarget ? 14 : 8)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { dropped, _ in
                defer { onCategoryDragEnd() }
                guard let payload = dropped.first,
                      payload.hasPrefix(categoryDragPrefix) else { return false }
                let name = String(payload.dropFirst(categoryDragPrefix.count))
                store.moveCategory(named: name, before: category)
                return true
            } isTargeted: { onCategoryDropTargetChanged($0) }
        }
    }

    @ViewBuilder
    private var sectionBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if canReorder {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                        .help("Drag header to reorder this category")
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        store.setAllPacked(tripID: tripID, category: category, packed: !allPacked)
                    }
                } label: {
                    if allPacked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.packitGreen)
                    } else {
                        DashedCircle(size: 17)
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .help(allPacked ? "Unpack all in \(category)" : "Pack all in \(category)")

                Image(systemName: store.categoryIcon(for: category))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(store.categoryColor(for: category))
                    .frame(width: 16)
                    .contentShape(Rectangle())
                    .help("Double-click to change icon")
                    .onTapGesture(count: 2) { showIconPicker = true }
                    .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                        InlineCategoryIconColorEditor(
                            categoryName: category,
                            onCommit: { isOpen in showIconPicker = isOpen }
                        )
                    }

                if isRenaming {
                    LeadingTextField(
                        label: "Category",
                        text: $renameText,
                        isFocused: $isRenameFocused,
                        autoFocus: true
                    )
                    .frame(width: 180, height: 22)
                    .onChange(of: isRenameFocused) { _, focused in
                        // NSTextField's controlTextDidEndEditing fires on Enter, Tab,
                        // click-outside, and Esc. Esc reverts the text first, so
                        // commitRename naturally no-ops in that case.
                        if !focused && isRenaming {
                            commitRename()
                        }
                    }
                } else {
                    Text(category.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.7))
                        .tracking(0.5)
                        .onTapGesture(count: 2) {
                            renameText = category == "Uncategorized" ? "" : category
                            isRenaming = true
                            // LeadingTextField with autoFocus: true takes focus + selects all.
                        }
                        .help("Double-click to rename")
                }
                Spacer()
                Text("\(packedCount)/\(items.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(packedCount == items.count ? Color.packitGreen : Color.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.vertical, 4)
            .background(isHeaderDropTargeted ? Color.packitTeal.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .modifier(CategoryHeaderDragModifier(
                category: category,
                canReorder: canReorder,
                onStart: onCategoryDragStart
            ))
            .dropDestination(for: String.self) { dropped, _ in
                guard let payload = dropped.first,
                      !payload.hasPrefix(categoryDragPrefix),
                      let draggedUUID = UUID(uuidString: payload) else { return false }
                store.moveTripItem(in: tripID, itemID: draggedUUID, toCategory: categoryForStore)
                return true
            } isTargeted: { isHeaderDropTargeted = $0 }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    PackingItemRow(
                        item: item,
                        tripID: tripID,
                        showOwnerSuffix: showOwnerSuffix,
                        isSelected: selectedItemIDs.contains(item.id),
                        selectionCount: selectedItemIDs.count,
                        isSearchMatch: searchMatchIDs.contains(item.id),
                        isCurrentSearchMatch: currentSearchMatchID == item.id,
                        onEdit: { onEdit(item) },
                        onSelect: { mods in onSelect(item, mods) },
                        onBulkSetOwner: { onBulkSetOwner($0) },
                        onBulkDuplicate: { onBulkDuplicate($0) },
                        onBulkRemove: { onBulkRemove() }
                    )
                    .id(item.id)
                        .draggable(item.id.uuidString)
                        .dropDestination(for: String.self) { droppedIDs, _ in
                            guard let droppedID = droppedIDs.first,
                                  let draggedUUID = UUID(uuidString: droppedID) else { return false }
                            store.moveTripItem(in: tripID, itemID: draggedUUID, before: item.id)
                            return true
                        }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }
}

private struct CategoryHeaderDragModifier: ViewModifier {
    let category: String
    let canReorder: Bool
    let onStart: () -> Void

    func body(content: Content) -> some View {
        if canReorder {
            content.draggable(categoryDragPrefix + category) {
                // Custom preview signals drag start so the parent can dim the
                // source section and reserve space in the drop strips below.
                Text(category)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onAppear { onStart() }
            }
        } else {
            content
        }
    }
}

// MARK: - Inspector View

struct TripInspectorView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @Binding var activeSheet: TripDetailView.TripSheet?
    let pendingReminders: Int
    @State private var newTodoText = ""
    @State private var newActivityText = ""
    @State private var newLinkLabel = ""
    @State private var newLinkURL = ""
    @State private var showAddLink = false
    @State private var editedNotes = ""
    @State private var notesExpanded = false
    @State private var notesCollapsed = false
    @State private var todosCollapsed = false
    @State private var activitiesCollapsed = false
    @State private var weatherCollapsed = false
    @State private var linksCollapsed = false
    @State private var infoCollapsed = false
    @FocusState private var todoFieldFocused: Bool
    @FocusState private var activityFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // TODOs
                todoSection

                Divider()

                // Activities
                activitiesSection

                Divider()

                // Weather
                WeatherWidget(trip: trip)

                Divider()

                // Notes
                notesSection

                Divider()

                // Reference Links
                referenceLinksSection

                Divider()

                // Trip Info
                infoSection
            }
            .padding()
        }
    }

    // MARK: - TODOs

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            inspectorHeader("TODOs", icon: "checklist", collapsed: $todosCollapsed)

            if !todosCollapsed {
            // Quick-add field
            HStack(spacing: 8) {
                TextField("Add a todo...", text: $newTodoText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($todoFieldFocused)
                    .onSubmit { addTodo() }
                    .padding(8)
                    .background(.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.packitTeal)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if trip.todos.isEmpty {
                Text("No TODOs yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(trip.todos) { todo in
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    store.toggleTodo(tripID: trip.id, todoID: todo.id)
                                }
                            } label: {
                                Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(todo.isComplete ? .packitGreen : .secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(todo.text)
                                    .font(.callout)
                                    .strikethrough(todo.isComplete)
                                    .foregroundStyle(todo.isComplete ? .secondary : .primary)
                                    .lineLimit(2)

                                if let due = todo.dueDate {
                                    Text(due.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(todo.isOverdue ? Color.packitRed : Color.secondary)
                                }
                            }

                            Spacer()

                            if !todo.isComplete {
                                PriorityBadge(priority: todo.priority)
                            }
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.removeTodo(from: trip.id, todoID: todo.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Summary
            if !trip.todos.isEmpty {
                let done = trip.todos.filter(\.isComplete).count
                Text("\(done)/\(trip.todos.count) complete")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            } // end if !todosCollapsed
        }
    }

    private func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTodo(to: trip.id, text: trimmed, dueDate: nil, priority: .medium)
        newTodoText = ""
        todoFieldFocused = true
    }

    // MARK: - Activities

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            inspectorHeader("Activities", icon: "sparkles", collapsed: $activitiesCollapsed)

            if !activitiesCollapsed {
            HStack(spacing: 8) {
                TextField("Add an activity...", text: $newActivityText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($activityFieldFocused)
                    .onSubmit { addActivity() }
                    .padding(8)
                    .background(.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: addActivity) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.packitTeal)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(newActivityText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if trip.activities.isEmpty {
                Text("Add planned activities for inspiration — dinners, excursions, sightseeing...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(trip.activities.sorted(by: { $0.sortOrder < $1.sortOrder })) { activity in
                        ActivityRow(activity: activity, tripID: trip.id)
                    }
                }
            }
            } // end if !activitiesCollapsed
        }
    }

    private func addActivity() {
        let trimmed = newActivityText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addActivity(to: trip.id, text: trimmed)
        newActivityText = ""
        activityFieldFocused = true
    }

    // MARK: - Reference Links

    private var referenceLinksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            inspectorHeader("Links", icon: "link", collapsed: $linksCollapsed, trailing: {
                Button {
                    showAddLink.toggle()
                    newLinkLabel = ""
                    newLinkURL = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.packitTeal)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            })

            if !linksCollapsed {
            if showAddLink {
                VStack(spacing: 4) {
                    TextField("Label", text: $newLinkLabel)
                        .textFieldStyle(.plain)
                        .font(.callout)
                    TextField("URL", text: $newLinkURL)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .onSubmit { addLink() }
                    HStack {
                        Button("Add") { addLink() }
                            .font(.caption)
                            .disabled(newLinkLabel.isEmpty || newLinkURL.isEmpty)
                        Button("Cancel") { showAddLink = false }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding(8)
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if trip.referenceLinks.isEmpty && !showAddLink {
                Text("Add useful links: campground, vet, park info...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(trip.referenceLinks) { link in
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption2)
                                .foregroundStyle(.packitTeal)
                            if let url = link.validURL {
                                Link(link.label, destination: url)
                                    .font(.callout)
                            } else {
                                Text(link.label)
                                    .font(.callout)
                            }
                            Spacer()
                        }
                        .contextMenu {
                            if let url = link.validURL {
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                                } label: {
                                    Label("Copy URL", systemImage: "doc.on.doc")
                                }
                            }
                            Divider()
                            Button(role: .destructive) {
                                store.removeReferenceLink(from: trip.id, linkID: link.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            } // end if !linksCollapsed
        }
    }

    @ViewBuilder
    private func renderedMarkdown(_ source: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(source.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if line.hasPrefix("# ") {
                    Text(mdInline(String(line.dropFirst(2))))
                        .font(.subheadline.bold())
                } else if line.hasPrefix("## ") {
                    Text(mdInline(String(line.dropFirst(3))))
                        .font(.callout.bold())
                } else if line.hasPrefix("### ") {
                    Text(mdInline(String(line.dropFirst(4))))
                        .font(.callout.weight(.semibold))
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 4) {
                        Text("•").foregroundStyle(.secondary).font(.caption)
                        Text(mdInline(String(line.dropFirst(2)))).font(.caption)
                    }
                } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 2)
                } else {
                    Text(mdInline(line)).font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mdInline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private func inspectorHeader(_ title: String, icon: String, collapsed: Binding<Bool>, @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    collapsed.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: collapsed.wrappedValue ? "chevron.right" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                        .frame(width: 8)
                    Label(title, systemImage: icon)
                        .font(.headline)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            trailing()
        }
    }

    private func addLink() {
        guard !newLinkLabel.isEmpty, !newLinkURL.isEmpty else { return }
        var url = newLinkURL
        if !url.contains("://") { url = "https://" + url }
        store.addReferenceLink(to: trip.id, label: newLinkLabel, url: url, category: nil)
        showAddLink = false
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            inspectorHeader("Notes", icon: "note.text", collapsed: $notesCollapsed)

            if !notesCollapsed {
            // Compact preview — click anywhere to pop out editor
            Group {
                if editedNotes.isEmpty {
                    Text("Click to add notes...")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                } else {
                    renderedMarkdown(editedNotes)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: 100)
            .padding(8)
            .background(.secondary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture { notesExpanded = true }
            .popover(isPresented: $notesExpanded, arrowEdge: .leading) {
                NotesEditorSheet(text: $editedNotes)
            }
            } // end if !notesCollapsed
        }
        .onAppear { editedNotes = trip.scratchNotes }
        .onChange(of: editedNotes) {
            var updated = trip
            updated.scratchNotes = editedNotes
            store.updateTrip(updated, actionName: "Edit Notes")
        }
    }


    // MARK: - Trip Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            inspectorHeader("Trip Info", icon: "info.circle", collapsed: $infoCollapsed)

            if !infoCollapsed {
            VStack(spacing: 6) {
                infoRow(icon: trip.travelMode.departureSymbol, label: "Departure", value: trip.departureDate.formatted(date: .long, time: .omitted))
                if let ret = trip.returnDate {
                    infoRow(icon: trip.travelMode.arrivalSymbol, label: "Return", value: ret.formatted(date: .long, time: .omitted))
                }
                infoRow(icon: "suitcase", label: "Status", value: trip.status.label)
                infoRow(icon: "number", label: "Items", value: "\(trip.totalItems)")
                if pendingReminders > 0 {
                    infoRow(icon: "bell.fill", label: "Reminders", value: "\(pendingReminders)")
                }
                if !trip.adHocItems.isEmpty {
                    infoRow(icon: "sparkles", label: "New Items", value: "\(trip.adHocItems.count)")
                }
            }
            } // end if !infoCollapsed
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.packitTeal)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

struct ActivityRow: View {
    @Environment(PackItStore.self) private var store
    let activity: TripActivity
    let tripID: UUID
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundStyle(.packitTeal)
                .padding(.top, 4)

            if isEditing {
                HStack(spacing: 4) {
                    TextField("Activity", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .onSubmit { saveEdit() }
                        .onExitCommand { isEditing = false }
                    Button { saveEdit() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.packitGreen)
                    }
                    .buttonStyle(.plain)
                    Button {
                        store.removeActivity(from: tripID, activityID: activity.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text(activity.text)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editText = activity.text
                        isEditing = true
                    }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                editText = activity.text
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                store.removeActivity(from: tripID, activityID: activity.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.updateActivity(tripID: tripID, activityID: activity.id, text: trimmed)
        isEditing = false
    }
}

