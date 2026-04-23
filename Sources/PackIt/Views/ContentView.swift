import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.undoManager) private var undoManager
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showNewTemplateSheet = false
    @State private var showNewTripSheet = false
    @State private var showQuickSearch = false
    @State private var showNewSharedSheet = false
    @State private var tripListWidth: CGFloat = 280

    var body: some View {
        @Bindable var store = store
        if store.tripDetailFullscreen, let trip = store.selectedTrip {
            fullscreenTripDetail(trip: trip)
        } else {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $store.navigation)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            detailContent
        }
        .onAppear {
            store.undoManager = undoManager
            store.loadAll()
        }
        .onChange(of: undoManager) { _, newValue in
            store.undoManager = newValue
        }
        .onChange(of: store.navigation) { oldVal, newVal in
            let oldSection = sidebarSection(oldVal)
            let newSection = sidebarSection(newVal)

            // Remember the previously-selected trip for its section before leaving.
            if let prevStatus = tripStatus(for: oldVal) {
                store.rememberSelectedTrip(store.selectedTripID, for: prevStatus)
            }

            if oldSection != newSection {
                if newSection != "templates" {
                    store.selectedTemplateID = nil
                }
                if newSection != "trips" {
                    store.selectedTripID = nil
                    tripListWidth = 280
                }
                if newSection != "tags" {
                    store.selectedTagID = nil
                }
                columnVisibility = .all
            }

            // Auto-select for the new trip section.
            if let newStatus = tripStatus(for: newVal) {
                autoSelectTrip(for: newStatus)
            }
        }
        .onChange(of: store.isLoading) { _, nowLoading in
            if !nowLoading, let status = tripStatus(for: store.navigation) {
                autoSelectTrip(for: status)
            }
        }
        .onChange(of: store.selectedTripID) { _, newID in
            if let status = tripStatus(for: store.navigation) {
                store.rememberSelectedTrip(newID, for: status)
            }
        }
        .onOpenURL { url in
            switch url.pathExtension {
            case "packitlist":
                store.importTrip(from: url)
            case "packittemplate":
                store.importTemplate(from: url)
            default:
                break
            }
        }
        .sheet(isPresented: $showNewTemplateSheet) {
            TemplateEditorSheet(template: nil)
        }
        .sheet(isPresented: $showNewTripSheet) {
            NewTripSheet()
        }
        .sheet(isPresented: $showQuickSearch) {
            SearchView()
        }
        .sheet(isPresented: $showNewSharedSheet) {
            NewSharedItemsSheet()
        }
        .onChange(of: store.newSharedItems.count) { _, newCount in
            if newCount > 0 && !showNewSharedSheet {
                showNewSharedSheet = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.pollSharedFolder()
        }
        .keyboardShortcut("n", modifiers: .command) {
            showNewTemplateSheet = true
        }
        .keyboardShortcut("n", modifiers: [.command, .shift]) {
            showNewTripSheet = true
        }
        .keyboardShortcut("k", modifiers: .command) {
            showQuickSearch = true
        }
        .frame(minWidth: 900, minHeight: 500)
        .overlay(alignment: .top) {
            // Conflict banner
            ForEach(store.conflicts) { conflict in
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.orange)
                    Text("\(conflict.modifiedBy) updated \(conflict.entityName)")
                        .font(.callout)
                    Spacer()
                    Button("OK") { store.dismissConflict(conflict) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 4)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            .animation(.easeInOut, value: store.conflicts.count)

            if let error = store.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.callout)
                    Spacer()
                    Button("Dismiss") {
                        store.error = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 4)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: store.error)
            }
        }
        } // end else (not fullscreen)
    }

    // MARK: - Fullscreen Trip Detail

    @ViewBuilder
    private func fullscreenTripDetail(trip: TripInstance) -> some View {
        VStack(spacing: 0) {
            // Thin toolbar with back button
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.tripDetailFullscreen = false
                    }
                } label: {
                    Label("Back to Trip List", systemImage: "chevron.left")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.packitTeal)
                Spacer()
                Text(trip.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                // Placeholder for symmetry
                Color.clear.frame(width: 120, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)

            TripDetailView(trip: trip)
                .environment(store)
        }
        .frame(minWidth: 900, minHeight: 500)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch sidebarSection(store.navigation) {
        case "templates":
            HStack(spacing: 0) {
                TemplateListView(showNewTemplateSheet: $showNewTemplateSheet)
                    .frame(width: 280)
                Divider()
                templateDetail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case "trips":
            HStack(spacing: 0) {
                tripListForCurrentSection
                    .frame(width: tripListWidth)
                    .animation(.easeInOut(duration: 0.2), value: tripListWidth)
                Divider()
                tripDetail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case "tags":
            HStack(spacing: 0) {
                TagManagerView()
                    .frame(width: 280)
                Divider()
                tagDetail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case "statistics":
            StatisticsView()
                .accessibilityIdentifier("detail.statistics")
        case "search":
            HStack(spacing: 0) {
                SearchView()
                    .frame(width: 280)
                Divider()
                ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search results appear in the left column."))
                    .accessibilityIdentifier("detail.search")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        default:
            ContentUnavailableView("PackIt", systemImage: "suitcase", description: Text("Select a section from the sidebar."))
                .accessibilityIdentifier("detail.empty")
        }
    }

    // MARK: - Trip List

    private func collapseTripList() {
        withAnimation(.easeInOut(duration: 0.25)) {
            tripListWidth = 54
        }
    }

    private func expandTripList() {
        withAnimation(.easeInOut(duration: 0.25)) {
            tripListWidth = 280
        }
    }

    @ViewBuilder
    private var tripListForCurrentSection: some View {
        switch store.navigation {
        case .tripsPlanning, .tripDetail:
            TripListView(trips: store.planningTrips, status: .planning, title: "Planning", showNewTripSheet: $showNewTripSheet, onCollapse: collapseTripList, onExpand: expandTripList)
        case .tripsActive:
            TripListView(trips: store.activeTrips, status: .active, title: "Active Trips", showNewTripSheet: $showNewTripSheet, onCollapse: collapseTripList, onExpand: expandTripList)
        case .tripsCompleted:
            TripListView(trips: store.completedTrips, status: .completed, title: "Completed", showNewTripSheet: $showNewTripSheet, onCollapse: collapseTripList, onExpand: expandTripList)
        case .tripsArchived:
            TripListView(trips: store.archivedTrips, status: .archived, title: "Archived", showNewTripSheet: $showNewTripSheet, onCollapse: collapseTripList, onExpand: expandTripList)
        default:
            EmptyView()
        }
    }

    // MARK: - Detail Panes

    @ViewBuilder
    private var templateDetail: some View {
        if let template = store.selectedTemplate {
            TemplateDetailView(template: template)
                .accessibilityIdentifier("detail.template")
        } else if store.templates.isEmpty {
            EmptyView()
        } else {
            ContentUnavailableView("No Selection", systemImage: "doc.on.doc", description: Text("Select a template to view its items."))
                .accessibilityIdentifier("detail.empty.template")
        }
    }

    @ViewBuilder
    private var tripDetail: some View {
        if let trip = store.selectedTrip {
            TripDetailView(trip: trip)
                .accessibilityIdentifier("detail.trip")
        } else {
            ContentUnavailableView("No Selection", systemImage: "suitcase", description: Text("Select a trip to view its details."))
                .accessibilityIdentifier("detail.empty.trip")
        }
    }

    @ViewBuilder
    private var tagDetail: some View {
        if let tag = store.selectedTag {
            TagDetailView(tag: tag)
                .accessibilityIdentifier("detail.tag")
        } else {
            ContentUnavailableView("No Selection", systemImage: "tag", description: Text("Select a tag to see its usage."))
                .accessibilityIdentifier("detail.empty.tag")
        }
    }

    private func tripStatus(for item: NavigationItem?) -> TripStatus? {
        switch item {
        case .tripsPlanning: return .planning
        case .tripsActive: return .active
        case .tripsCompleted: return .completed
        case .tripsArchived: return .archived
        default: return nil
        }
    }

    private func autoSelectTrip(for status: TripStatus) {
        let list = store.trips(for: status)
        guard !list.isEmpty else {
            store.selectedTripID = nil
            return
        }
        if let remembered = store.lastSelectedTrip(for: status), list.contains(where: { $0.id == remembered }) {
            store.selectedTripID = remembered
        } else if store.selectedTripID == nil || list.contains(where: { $0.id == store.selectedTripID }) == false {
            store.selectedTripID = list.first?.id
        }
    }

    private func sidebarSection(_ item: NavigationItem?) -> String {
        switch item {
        case .templates, .templateDetail: return "templates"
        case .tripsPlanning, .tripsActive, .tripsCompleted, .tripsArchived, .tripDetail: return "trips"
        case .tags: return "tags"
        case .statistics: return "statistics"
        case .search: return "search"
        case nil: return ""
        }
    }
}

private extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        background(
            Button("") { action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .hidden()
        )
    }
}
