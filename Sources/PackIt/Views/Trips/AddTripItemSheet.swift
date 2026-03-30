import SwiftUI

struct AddTripItemSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID

    @State private var name = ""
    @State private var category = ""
    @State private var priority: Priority = .medium

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Item Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Category (optional)", text: $category)
                    .textFieldStyle(.roundedBorder)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Label(p.label, systemImage: p.icon).tag(p)
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
                Button("Add Item") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.addAdHocItem(
                        to: tripID,
                        name: trimmed,
                        category: category.isEmpty ? nil : category,
                        priority: priority
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}
