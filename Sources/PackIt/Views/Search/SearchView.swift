import SwiftUI

struct SearchView: View {
    @Environment(PackItStore.self) private var store
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search templates and trips...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Divider()

            if query.isEmpty {
                ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search across all templates and trips."))
            } else {
                List {
                    let matchingTemplates = store.templates.filter { matchesTemplate($0, query: query) }
                    let matchingTrips = store.trips.filter { matchesTrip($0, query: query) }

                    if !matchingTemplates.isEmpty {
                        Section("Templates") {
                            ForEach(matchingTemplates) { template in
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(template.name)
                                            .font(.headline)
                                        Text("\(template.itemCount) items")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .onTapGesture {
                                    store.navigation = .templateDetail(template.id)
                                    store.selectedTemplateID = template.id
                                }
                            }
                        }
                    }

                    if !matchingTrips.isEmpty {
                        Section("Trips") {
                            ForEach(matchingTrips) { trip in
                                HStack {
                                    Image(systemName: trip.status.icon)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading) {
                                        Text(trip.name)
                                            .font(.headline)
                                        Text("\(trip.departureDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.status.label)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .onTapGesture {
                                    store.navigation = .tripDetail(trip.id)
                                    store.selectedTripID = trip.id
                                }
                            }
                        }
                    }

                    if matchingTemplates.isEmpty && matchingTrips.isEmpty {
                        ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No templates or trips match \"\(query)\"."))
                    }
                }
            }
        }
        .navigationTitle("Search")
    }

    private func matchesTemplate(_ template: PackingTemplate, query: String) -> Bool {
        let q = query.lowercased()
        return template.name.lowercased().contains(q) ||
            template.contextTags.contains { $0.lowercased().contains(q) } ||
            template.items.contains { $0.name.lowercased().contains(q) }
    }

    private func matchesTrip(_ trip: TripInstance, query: String) -> Bool {
        let q = query.lowercased()
        return trip.name.lowercased().contains(q) ||
            trip.items.contains { $0.name.lowercased().contains(q) } ||
            trip.todos.contains { $0.text.lowercased().contains(q) } ||
            trip.scratchNotes.lowercased().contains(q)
    }
}
