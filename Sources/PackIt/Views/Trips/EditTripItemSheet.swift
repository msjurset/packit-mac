import SwiftUI

/// Edit an existing TripItem: name, category, owner, priority, qty, notes.
struct EditTripItemSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID
    let originalItem: TripItem

    @State private var name = ""
    @State private var category = ""
    @State private var notes = ""
    @State private var selectedOwners: Set<String> = []
    @State private var priority: Priority = .medium
    @State private var quantity = 1

    private var trip: TripInstance? {
        store.trips.first { $0.id == tripID }
    }

    private var orderedSelectedOwners: [String] {
        guard let trip else { return [] }
        return trip.members.filter { selectedOwners.contains($0) }
    }

    var body: some View {
        FormSheet(width: 440, height: 480) {
            Section("Item") {
                LeadingTextField(label: "Name", text: $name)
                CategoryField(text: $category)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Label(p.label, systemImage: p.icon).tag(p)
                    }
                }
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
            }

            if let trip, !trip.members.isEmpty {
                Section("Owners") {
                    ForEach(trip.members, id: \.self) { member in
                        Toggle(isOn: Binding(
                            get: { selectedOwners.contains(member) },
                            set: { isOn in
                                if isOn { selectedOwners.insert(member) }
                                else { selectedOwners.remove(member) }
                            }
                        )) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundStyle(.packitTeal)
                                Text(member)
                            }
                        }
                    }
                    Text(ownersHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            name = originalItem.name
            category = originalItem.category ?? ""
            notes = originalItem.notes ?? ""
            priority = originalItem.priority
            quantity = originalItem.quantity
            if let owner = originalItem.owner, !owner.isEmpty {
                selectedOwners = [owner]
            } else {
                selectedOwners = []
            }
        }
    }

    private var ownersHint: String {
        switch orderedSelectedOwners.count {
        case 0:
            return "Shared with everyone — one item, no specific owner."
        case 1:
            return "Owned by \(orderedSelectedOwners[0])."
        default:
            let extras = orderedSelectedOwners.count - 1
            return "On save, this item stays with \(orderedSelectedOwners[0]) and \(extras) duplicate\(extras == 1 ? "" : "s") will be created (one per additional owner)."
        }
    }

    private func save() {
        var updated = originalItem
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.category = category.isEmpty ? nil : category
        updated.notes = notes.isEmpty ? nil : notes
        updated.priority = priority
        updated.quantity = max(1, quantity)

        let owners = orderedSelectedOwners
        if owners.isEmpty {
            updated.owner = nil
            store.applyItemEdit(in: tripID, item: updated, additionalOwners: [])
        } else {
            updated.owner = owners[0]
            store.applyItemEdit(in: tripID, item: updated, additionalOwners: Array(owners.dropFirst()))
        }
        dismiss()
    }
}
