import SwiftUI
import PackItKit

struct SidebarView: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @Binding var selection: NavigationItem?

    var body: some View {
        List(selection: $selection) {
            Section("Templates") {
                sidebarRow("All Templates", icon: "doc.on.doc", tag: .templates, count: store.templates.count)
                    .accessibilityIdentifier("sidebar.templates")
            }

            Section("Trips") {
                sidebarRow("Planning", icon: "pencil.and.list.clipboard", tag: .tripsPlanning, count: store.planningTrips.count)
                    .accessibilityIdentifier("sidebar.planning")
                sidebarRow("Active", icon: "suitcase.fill", tag: .tripsActive, count: store.activeTrips.count)
                    .accessibilityIdentifier("sidebar.active")
                sidebarRow("Completed", icon: "checkmark.circle.fill", tag: .tripsCompleted, count: store.completedTrips.count)
                    .accessibilityIdentifier("sidebar.completed")
                sidebarRow("Archived", icon: "archivebox", tag: .tripsArchived, count: store.archivedTrips.count)
                    .accessibilityIdentifier("sidebar.archived")
            }

            Section("Manage") {
                sidebarRow("Tags", icon: "tag", tag: .tags, count: store.tags.count)
                    .accessibilityIdentifier("sidebar.tags")

                Label("Statistics", systemImage: "chart.bar")
                    .tag(NavigationItem.statistics)
                    .accessibilityIdentifier("sidebar.statistics")

                Label("Search", systemImage: "magnifyingglass")
                    .tag(NavigationItem.search)
                    .accessibilityIdentifier("sidebar.search")
            }
        }
        .listStyle(.sidebar)
        .accessibilityIdentifier("sidebar")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                WisdomBanner()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxHeight: 160)

                HStack(spacing: 12) {
                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")

                    Button {
                        openWindow(id: "help")
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Help")

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("PackIt")
    }

    private func sidebarRow(_ title: String, icon: String, tag: NavigationItem, count: Int) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .tag(tag)
    }
}
