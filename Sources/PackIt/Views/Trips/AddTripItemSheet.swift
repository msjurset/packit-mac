import SwiftUI

struct AddTripItemSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID

    @State private var name = ""
    @State private var category = ""
    @State private var priority: Priority = .medium
    @State private var quantity = 1

    private var existingNames: Set<String> {
        guard let trip = store.trips.first(where: { $0.id == tripID }) else { return [] }
        return Set(trip.items.map(\.name))
    }

    var body: some View {
        FormSheet(width: 400, height: 350) {
            ItemSuggestField(
                text: $name,
                excludeNames: existingNames
            ) { accepted in
                if let source = store.templateItem(named: accepted) {
                    if category.isEmpty, let cat = source.category { category = cat }
                    priority = source.priority
                    if quantity == 1 && source.quantity > 1 { quantity = source.quantity }
                }
            }
            CategoryField(text: $category)
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { p in
                    Label(p.label, systemImage: p.icon).tag(p)
                }
            }
            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Add Item") {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                store.addAdHocItem(
                    to: tripID,
                    name: trimmed,
                    category: category.isEmpty ? nil : category,
                    priority: priority,
                    quantity: quantity
                )
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
