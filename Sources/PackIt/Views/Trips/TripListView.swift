import SwiftUI

struct TripListView: View {
    @Environment(PackItStore.self) private var store
    let trips: [TripInstance]
    let title: String
    @Binding var showNewTripSheet: Bool

    var body: some View {
        Group {
            if trips.isEmpty {
                ContentUnavailableView {
                    Label("No \(title) Trips", systemImage: "suitcase")
                } description: {
                    Text("Create a new trip to get started.")
                } actions: {
                    Button("New Trip") {
                        showNewTripSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(trips) { trip in
                        TripRow(trip: trip)
                            .tag(NavigationItem.tripDetail(trip.id))
                            .onTapGesture(count: 1) {
                                store.navigation = .tripDetail(trip.id)
                                store.selectedTripID = trip.id
                            }
                            .contextMenu {
                                if trip.status != .archived {
                                    Button("Archive") {
                                        var updated = trip
                                        updated.status = .archived
                                        store.updateTrip(updated)
                                    }
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    store.deleteTrip(id: trip.id)
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}

struct TripRow: View {
    let trip: TripInstance

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                Spacer()
                Image(systemName: trip.status.icon)
                    .foregroundStyle(statusColor)
            }
            HStack(spacing: 12) {
                Label(trip.departureDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView(value: trip.progress)
                    .frame(width: 60)

                Text("\(trip.packedCount)/\(trip.totalItems)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !trip.overdueItems.isEmpty {
                    Label("\(trip.overdueItems.count) overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch trip.status {
        case .planning: return .blue
        case .active: return .green
        case .completed: return .secondary
        case .archived: return .secondary
        }
    }
}
