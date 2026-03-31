import SwiftUI

struct TripListView: View {
    @Environment(PackItStore.self) private var store
    let trips: [TripInstance]
    let title: String
    @Binding var showNewTripSheet: Bool
    @State private var tripToDelete: TripInstance?

    var body: some View {
        @Bindable var store = store
        Group {
            if trips.isEmpty {
                ContentUnavailableView {
                    Label("No \(title)", systemImage: "suitcase")
                } description: {
                    Text("Create a new trip to get started.")
                } actions: {
                    Button("New Trip") {
                        showNewTripSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.packitTeal)
                }
            } else {
                List {
                    ForEach(trips) { trip in
                        Button {
                            store.selectedTripID = trip.id
                            store.navigation = .tripDetail(trip.id)
                        } label: {
                            TripRow(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            store.selectedTripID == trip.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .contextMenu {
                                if trip.status == .planning {
                                    Button {
                                        var updated = trip
                                        updated.status = .active
                                        store.updateTrip(updated)
                                    } label: {
                                        Label("Start Packing", systemImage: "suitcase.fill")
                                    }
                                }
                                if trip.status == .active {
                                    Button {
                                        var updated = trip
                                        updated.status = .completed
                                        store.updateTrip(updated)
                                    } label: {
                                        Label("Mark Completed", systemImage: "checkmark.circle")
                                    }
                                }
                                if trip.status != .archived {
                                    Button {
                                        var updated = trip
                                        updated.status = .archived
                                        store.updateTrip(updated)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                }
                                Divider()
                                Button(role: .destructive) {
                                    tripToDelete = trip
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(title)
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button { showNewTripSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)
                .help("New trip (⌘⇧N)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .alert("Delete Trip?", isPresented: .init(
            get: { tripToDelete != nil },
            set: { if !$0 { tripToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { tripToDelete = nil }
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    store.deleteTrip(id: trip.id)
                }
                tripToDelete = nil
            }
        } message: {
            if let trip = tripToDelete {
                Text("This will permanently delete \"\(trip.name)\" and all its items.")
            }
        }
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
                    .foregroundStyle(Color.statusColor(trip.status))
                    .font(.callout)
            }
            HStack(spacing: 12) {
                Label(trip.departureDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView(value: trip.progress)
                    .tint(progressTint)
                    .frame(width: 60)

                Text("\(trip.packedCount)/\(trip.totalItems)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                if !trip.overdueItems.isEmpty {
                    Label("\(trip.overdueItems.count) overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.packitRed)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var progressTint: Color {
        if trip.progress >= 1.0 { return .packitGreen }
        if trip.progress >= 0.5 { return .packitTeal }
        return .orange
    }
}
