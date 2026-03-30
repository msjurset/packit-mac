import SwiftUI

struct SidebarView: View {
    @Environment(PackItStore.self) private var store
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Templates") {
                Label("All Templates", systemImage: "doc.on.doc")
                    .tag(SidebarItem.templates)
                    .badge(store.templates.count)
            }

            Section("Trips") {
                Label("Planning", systemImage: "pencil.and.list.clipboard")
                    .tag(SidebarItem.tripsPlanning)
                    .badge(store.planningTrips.count)

                Label("Active", systemImage: "suitcase.fill")
                    .tag(SidebarItem.tripsActive)
                    .badge(store.activeTrips.count)

                Label("Completed", systemImage: "checkmark.circle.fill")
                    .tag(SidebarItem.tripsCompleted)
                    .badge(store.completedTrips.count)

                Label("Archived", systemImage: "archivebox")
                    .tag(SidebarItem.tripsArchived)
                    .badge(store.archivedTrips.count)
            }

            Section("Manage") {
                Label("Tags", systemImage: "tag")
                    .tag(SidebarItem.tags)
                    .badge(store.tags.count)

                Label("Search", systemImage: "magnifyingglass")
                    .tag(SidebarItem.search)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PackIt")
    }
}
