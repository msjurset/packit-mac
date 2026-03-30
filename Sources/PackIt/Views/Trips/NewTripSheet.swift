import SwiftUI

struct NewTripSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var departureDate = Date.now
    @State private var returnDate = Date.now.addingTimeInterval(7 * 86400)
    @State private var hasReturnDate = true
    @State private var selectedTemplateIDs: Set<UUID> = []
    @State private var selectedTags: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                    Toggle("Return Date", isOn: $hasReturnDate)
                    if hasReturnDate {
                        DatePicker("Return", selection: $returnDate, displayedComponents: .date)
                    }
                }

                Section("Start from Templates") {
                    if store.templates.isEmpty {
                        Text("No templates yet. You can add items manually after creating the trip.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(store.templates) { template in
                            Toggle(isOn: Binding(
                                get: { selectedTemplateIDs.contains(template.id) },
                                set: { isOn in
                                    if isOn { selectedTemplateIDs.insert(template.id) }
                                    else { selectedTemplateIDs.remove(template.id) }
                                }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                    Text("\(template.itemCount) items")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !store.allTagNames.isEmpty && !selectedTemplateIDs.isEmpty {
                    Section("Filter by Context Tags") {
                        Text("Only include items matching these tags (leave empty for all items).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(store.allTagNames, id: \.self) { tag in
                                TagChip(name: tag, isSelected: selectedTags.contains(tag)) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(previewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Create Trip") { createTrip() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 550, height: 600)
    }

    private var previewText: String {
        let templates = store.templates.filter { selectedTemplateIDs.contains($0.id) }
        let itemCount = templates.reduce(0) { $0 + $1.itemCount }
        if templates.isEmpty { return "Empty trip" }
        return "~\(itemCount) items from \(templates.count) template\(templates.count == 1 ? "" : "s")"
    }

    private func createTrip() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let trip = store.createTrip(
            name: trimmed,
            departureDate: departureDate,
            returnDate: hasReturnDate ? returnDate : nil,
            templateIDs: Array(selectedTemplateIDs),
            selectedTags: Array(selectedTags)
        )
        store.sidebarSelection = .tripsPlanning
        store.selectedTripID = trip.id
        dismiss()
    }
}
