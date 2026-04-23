import SwiftUI
import UniformTypeIdentifiers

struct TripListView: View {
    @Environment(PackItStore.self) private var store
    let trips: [TripInstance]
    let status: TripStatus
    let title: String
    @Binding var showNewTripSheet: Bool
    var onCollapse: (() -> Void)?
    var onExpand: (() -> Void)?
    @State private var tripToDelete: TripInstance?
    @State private var showImporter = false
    @State private var exportingTrip: TripInstance?
    @State private var dropTargetID: UUID?
    @State private var draggingID: UUID?

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
            } else if store.tripListCompact {
                // Compact: ScrollView for full layout control
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(trips) { trip in
                            TripIconView(icon: trip.icon, size: 28, showBackground: true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(store.selectedTripID == trip.id ? trip.icon.color : .clear, lineWidth: 2)
                                )
                                .help(trip.name)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    store.selectedTripID == trip.id
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onTapGesture {
                                    if store.selectedTripID == trip.id {
                                        onExpand?()
                                        store.tripListCompact = false
                                    } else {
                                        store.selectedTripID = trip.id
                                        store.navigation = .tripDetail(trip.id)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                // Expanded: ScrollView for full click control
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(trips) { trip in
                            TripRow(trip: trip, isReceivedShare: store.isReceivedShare(tripID: trip.id))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(
                                    store.selectedTripID == trip.id
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.primary.opacity(0.001)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .opacity(draggingID == trip.id ? 0.35 : 1)
                                .padding(.top, dropTargetID == trip.id ? 10 : 0)
                                .overlay(alignment: .top) {
                                    if dropTargetID == trip.id {
                                        Capsule()
                                            .fill(Color.accentColor)
                                            .frame(height: 3)
                                            .padding(.horizontal, 6)
                                            .transition(.opacity)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.15), value: dropTargetID)
                                .animation(.easeInOut(duration: 0.15), value: draggingID)
                                .draggable(trip.id.uuidString) {
                                    TripRow(trip: trip, isReceivedShare: false)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .onAppear { draggingID = trip.id }
                                }
                                .dropDestination(for: String.self) { items, _ in
                                    defer { dropTargetID = nil; draggingID = nil }
                                    guard let raw = items.first, let sourceID = UUID(uuidString: raw) else { return false }
                                    store.reorderTrip(draggingID: sourceID, before: trip.id, in: status)
                                    return true
                                } isTargeted: { targeted in
                                    if targeted {
                                        dropTargetID = trip.id
                                    } else if dropTargetID == trip.id {
                                        dropTargetID = nil
                                    }
                                }
                                .onTapGesture {
                                    if store.selectedTripID == trip.id {
                                        onCollapse?()
                                        store.tripListCompact = true
                                    } else {
                                        store.selectedTripID = trip.id
                                        store.navigation = .tripDetail(trip.id)
                                    }
                                }
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
                                    Button {
                                        exportingTrip = trip
                                    } label: {
                                        Label("Export...", systemImage: "square.and.arrow.up")
                                    }
                                    Divider()
                                    Divider()
                                    shareTripMenu(trip)
                                    Button(role: .destructive) {
                                        tripToDelete = trip
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .contextMenu {
                    Button { showNewTripSheet = true } label: {
                        Label("New Trip", systemImage: "plus")
                    }
                    Button { showImporter = true } label: {
                        Label("Import Trip...", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .accessibilityIdentifier("tripList")
        .navigationTitle(title)
        .safeAreaInset(edge: .top, spacing: 0) {
            if store.tripListCompact {
                Button { showNewTripSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("New trip (⌘⇧N)")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                HStack {
                    Spacer()
                    Button { showImporter = true } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .foregroundStyle(.secondary)
                    .help("Import trip file")
                    Button { showNewTripSheet = true } label: {
                        Label("Add Trip", systemImage: "plus.circle")
                            .font(.caption)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .foregroundStyle(.packitTeal)
                    .help("New trip (⌘⇧N)")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
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
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType(exportedAs: "com.msjurset.packit.list"), .json], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    store.importTrip(from: url)
                }
            }
        }
        .sheet(item: $exportingTrip) { trip in
            ExportSheet(trip: trip)
        }
    }

    @ViewBuilder
    private func shareTripMenu(_ trip: TripInstance) -> some View {
        if store.localConfig.hasSharedPath {
            if store._sharedTripIDs.contains(trip.id) {
                Button { store.unshareTrip(id: trip.id) } label: {
                    Label("Unshare", systemImage: "person.crop.circle.badge.minus")
                }
            } else {
                Button { store.shareTrip(id: trip.id) } label: {
                    Label("Share", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct TripRow: View {
    let trip: TripInstance
    var isReceivedShare: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TripIconView(icon: trip.icon, size: 26)
                Text(trip.name)
                    .font(.headline)
                if isReceivedShare {
                    SharedBadge(author: trip.createdBy, compact: true)
                }
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

struct ResponsiveTripRow: View {
    let trip: TripInstance
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            if geo.size.width < 200 {
                // Icon-only mode — tight, centered
                HStack {
                    Spacer(minLength: 0)
                    TripIconView(icon: trip.icon, size: 28, showBackground: true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(isSelected ? trip.icon.color : .clear, lineWidth: 2)
                        )
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .help(trip.name)
            } else {
                TripRow(trip: trip)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
        .frame(minHeight: 40)
    }
}
