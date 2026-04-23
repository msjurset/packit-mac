import SwiftUI

/// Middle column: shows list based on sidebar selection.
struct ContentListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @Binding var showNewTripSheet: Bool

    var body: some View {
        switch store.navigation {
        case .templates, .templateDetail:
            TemplateListView(showNewTemplateSheet: $showNewTemplateSheet)
        case .tripsPlanning, .tripDetail:
            TripListView(trips: store.planningTrips, status: .planning, title: "Planning", showNewTripSheet: $showNewTripSheet)
        case .tripsActive:
            TripListView(trips: store.activeTrips, status: .active, title: "Active Trips", showNewTripSheet: $showNewTripSheet)
        case .tripsCompleted:
            TripListView(trips: store.completedTrips, status: .completed, title: "Completed", showNewTripSheet: $showNewTripSheet)
        case .tripsArchived:
            TripListView(trips: store.archivedTrips, status: .archived, title: "Archived", showNewTripSheet: $showNewTripSheet)
        case .tags:
            TagManagerView()
        case .statistics:
            EmptyView()
        case .search:
            SearchView()
        case nil:
            ContentUnavailableView("PackIt", systemImage: "suitcase", description: Text("Select a section from the sidebar."))
        }
    }
}

/// Right column: shows detail for selected item.
struct DetailView: View {
    @Environment(PackItStore.self) private var store

    private var tripsForCurrentSection: [TripInstance] {
        switch store.navigation {
        case .tripsPlanning: return store.planningTrips
        case .tripsActive: return store.activeTrips
        case .tripsCompleted: return store.completedTrips
        case .tripsArchived: return store.archivedTrips
        default: return []
        }
    }

    var body: some View {
        switch store.navigation {
        case .templates, .templateDetail:
            if let template = store.selectedTemplate {
                TemplateDetailView(template: template)
                    .accessibilityIdentifier("detail.template")
            } else if store.templates.isEmpty {
                EmptyView()
            } else {
                ContentUnavailableView("No Selection", systemImage: "doc.on.doc", description: Text("Select a template to view its items."))
                    .accessibilityIdentifier("detail.empty.template")
            }
        case .tripsPlanning, .tripsActive, .tripsCompleted, .tripsArchived, .tripDetail:
            if let trip = store.selectedTrip {
                TripDetailView(trip: trip)
                    .accessibilityIdentifier("detail.trip")
            } else if tripsForCurrentSection.isEmpty {
                EmptyView()
            } else {
                ContentUnavailableView("No Selection", systemImage: "suitcase", description: Text("Select a trip to view its details."))
                    .accessibilityIdentifier("detail.empty.trip")
            }
        case .tags:
            if let tag = store.selectedTag {
                TagDetailView(tag: tag)
                    .accessibilityIdentifier("detail.tag")
            } else {
                ContentUnavailableView("No Selection", systemImage: "tag", description: Text("Select a tag to see its usage."))
                    .accessibilityIdentifier("detail.empty.tag")
            }
        case .statistics:
            StatisticsView()
                .accessibilityIdentifier("detail.statistics")
        case .search:
            ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search results appear in the middle column."))
                .accessibilityIdentifier("detail.search")
        case nil:
            ContentUnavailableView("PackIt", systemImage: "suitcase", description: Text("Select a section from the sidebar."))
                .accessibilityIdentifier("detail.empty")
        }
    }
}
