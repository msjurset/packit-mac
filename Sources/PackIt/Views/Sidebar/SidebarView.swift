import SwiftUI
import PackItKit

struct SidebarView: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @Binding var selection: NavigationItem?

    @State private var targetedStatus: TripStatus?

    var body: some View {
        List(selection: $selection) {
            if !store.pinnedTrips.isEmpty {
                Section("Pinned") {
                    ForEach(store.pinnedTrips) { trip in
                        pinnedTripRow(trip)
                    }
                }
            }

            Section("Trips") {
                sidebarRow("Planning", icon: "pencil.and.list.clipboard", tag: .tripsPlanning, status: .planning, count: store.planningTrips.count)
                    .accessibilityIdentifier("sidebar.planning")
                sidebarRow("Active", icon: "suitcase.fill", tag: .tripsActive, status: .active, count: store.activeTrips.count)
                    .accessibilityIdentifier("sidebar.active")
                sidebarRow("Completed", icon: "checkmark.circle.fill", tag: .tripsCompleted, status: .completed, count: store.completedTrips.count)
                    .accessibilityIdentifier("sidebar.completed")
                sidebarRow("Archived", icon: "archivebox", tag: .tripsArchived, status: .archived, count: store.archivedTrips.count)
                    .accessibilityIdentifier("sidebar.archived")
            }

            Section("Templates") {
                sidebarRow("All Templates", icon: "doc.on.doc", tag: .templates, status: nil, count: store.templates.count)
                    .accessibilityIdentifier("sidebar.templates")
            }

            Section("Manage") {
                sidebarRow("Tags", icon: "tag", tag: .tags, status: nil, count: store.tags.count)
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

    private func sidebarRow(_ title: String, icon: String, tag: NavigationItem, status: TripStatus?, count: Int) -> some View {
        let isTargeted = status != nil && targetedStatus == status
        return HStack {
            Label(title, systemImage: icon)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isTargeted ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isTargeted ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
        .tag(tag)
        .dropDestination(for: String.self) { items, _ in
            guard let status else { return false }
            return moveDroppedTrip(items, to: status)
        } isTargeted: { targeted in
            guard let status else { return }
            if targeted {
                targetedStatus = status
            } else if targetedStatus == status {
                targetedStatus = nil
            }
        }
    }

    private func moveDroppedTrip(_ items: [String], to targetStatus: TripStatus) -> Bool {
        guard let raw = items.first, let tripID = UUID(uuidString: raw) else { return false }
        if var trip = store.trips.first(where: { $0.id == tripID }) {
            if trip.status != targetStatus {
                trip.status = targetStatus
                store.updateTrip(trip)
            }
            return true
        }
        return false
    }

    private func pinnedTripRow(_ trip: TripInstance) -> some View {
        HStack(spacing: 6) {
            Image(systemName: trip.icon.symbol)
                .foregroundStyle(.packitTeal)
                .frame(width: 18)
            Text(trip.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .tag(NavigationItem.tripDetail(trip.id))
        .draggable(trip.id.uuidString)
        .contextMenu {
            Button(trip.isPinned ? "Unpin" : "Pin", systemImage: trip.isPinned ? "pin.slash" : "pin") {
                store.togglePin(tripID: trip.id)
            }
            Divider()
            Picker("Trip Status", selection: Binding(
                get: { trip.status },
                set: { newStatus in
                    var updated = trip
                    updated.status = newStatus
                    store.updateTrip(updated)
                }
            )) {
                ForEach(TripStatus.allCases, id: \.self) { status in
                    Label(status.label, systemImage: status.icon)
                        .tag(status)
                }
            }
        }
    }
}
