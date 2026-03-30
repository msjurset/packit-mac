import SwiftUI

/// Middle column: shows list of items based on sidebar selection.
struct ContentListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @Binding var showNewTripSheet: Bool

    var body: some View {
        switch store.sidebarSelection {
        case .templates:
            TemplateListView(showNewTemplateSheet: $showNewTemplateSheet)
        case .tripsPlanning:
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

/// Right column: shows detail for selected template or trip.
struct DetailView: View {
    @Environment(PackItStore.self) private var store

    var body: some View {
        if let template = store.selectedTemplate,
           store.sidebarSelection == .templates {
            TemplateDetailView(template: template)
        } else if let trip = store.selectedTrip {
            TripDetailView(trip: trip)
        } else {
            ContentUnavailableView("No Selection", systemImage: "sidebar.right", description: Text("Select an item to view its details."))
        }
    }
}
