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
            TripListView(trips: store.planningTrips, title: "Planning", showNewTripSheet: $showNewTripSheet)
        case .tripsActive:
            TripListView(trips: store.activeTrips, title: "Active Trips", showNewTripSheet: $showNewTripSheet)
        case .tripsCompleted:
            TripListView(trips: store.completedTrips, title: "Completed", showNewTripSheet: $showNewTripSheet)
        case .tripsArchived:
            TripListView(trips: store.archivedTrips, title: "Archived", showNewTripSheet: $showNewTripSheet)
        case .tags:
            TagManagerView()
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

    var body: some View {
        switch store.navigation {
        case .templates, .templateDetail:
            if let template = store.selectedTemplate {
                TemplateDetailView(template: template)
            } else {
                ContentUnavailableView("No Selection", systemImage: "doc.on.doc", description: Text("Select a template to view its items."))
            }
        case .tripsPlanning, .tripsActive, .tripsCompleted, .tripsArchived, .tripDetail:
            if let trip = store.selectedTrip {
                TripDetailView(trip: trip)
            } else {
                ContentUnavailableView("No Selection", systemImage: "suitcase", description: Text("Select a trip to view its details."))
            }
        case .tags:
            ContentUnavailableView("Tags", systemImage: "tag", description: Text("Manage context tags in the middle column."))
        case .search:
            ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search results appear in the middle column."))
        case nil:
            ContentUnavailableView("PackIt", systemImage: "suitcase", description: Text("Select a section from the sidebar."))
        }
    }
}
