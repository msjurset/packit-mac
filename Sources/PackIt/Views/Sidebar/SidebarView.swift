import SwiftUI

struct SidebarView: View {
    @Environment(PackItStore.self) private var store
    @Binding var selection: NavigationItem?

    var body: some View {
        List(selection: $selection) {
            Section("Templates") {
                Label("All Templates", systemImage: "doc.on.doc")
                    .tag(NavigationItem.templates)
                    .badge(store.templates.count)
            }

            Section("Trips") {
                Label("Planning", systemImage: "pencil.and.list.clipboard")
                    .tag(NavigationItem.tripsPlanning)
                    .badge(store.planningTrips.count)

                Label("Active", systemImage: "suitcase.fill")
                    .tag(NavigationItem.tripsActive)
                    .badge(store.activeTrips.count)

                Label("Completed", systemImage: "checkmark.circle.fill")
                    .tag(NavigationItem.tripsCompleted)
                    .badge(store.completedTrips.count)

                Label("Archived", systemImage: "archivebox")
                    .tag(NavigationItem.tripsArchived)
                    .badge(store.archivedTrips.count)
            }

            Section("Manage") {
                Label("Tags", systemImage: "tag")
                    .tag(NavigationItem.tags)
                    .badge(store.tags.count)

                Label("Search", systemImage: "magnifyingglass")
                    .tag(NavigationItem.search)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PackIt")
    }
}
