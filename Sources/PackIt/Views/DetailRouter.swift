import SwiftUI

struct DetailRouter: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @Binding var showNewTripSheet: Bool

    var body: some View {
        switch store.navigation {
        case .templates:
            TemplateListView(showNewTemplateSheet: $showNewTemplateSheet)
        case .templateDetail(let id):
            if let template = store.templates.first(where: { $0.id == id }) {
                TemplateDetailView(template: template)
            } else {
                emptyState("Template not found")
            }
        case .tripsPlanning:
            TripListView(trips: store.planningTrips, title: "Planning", showNewTripSheet: $showNewTripSheet)
        case .tripsActive:
            TripListView(trips: store.activeTrips, title: "Active Trips", showNewTripSheet: $showNewTripSheet)
        case .tripsCompleted:
            TripListView(trips: store.completedTrips, title: "Completed", showNewTripSheet: $showNewTripSheet)
        case .tripsArchived:
            TripListView(trips: store.archivedTrips, title: "Archived", showNewTripSheet: $showNewTripSheet)
        case .tripDetail(let id):
            if let trip = store.trips.first(where: { $0.id == id }) {
                TripDetailView(trip: trip)
            } else {
                emptyState("Trip not found")
            }
        case .tags:
            TagManagerView()
        case .search:
            SearchView()
        case nil:
            emptyState("Select an item from the sidebar")
        }
    }

    private func emptyState(_ message: String) -> some View {
        ContentUnavailableView(message, systemImage: "suitcase")
    }
}
