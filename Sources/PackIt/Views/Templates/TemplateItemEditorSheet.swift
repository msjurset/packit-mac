import SwiftUI

struct TemplateItemEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let templateID: UUID
    let item: TemplateItem?

    @State private var name = ""
    @State private var category = ""
    @State private var priority: Priority = .medium
    @State private var notes = ""
    @State private var selectedTags: Set<String> = []

    private var isNew: Bool { item == nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    TextField("Category (optional)", text: $category)
                        .textFieldStyle(.roundedBorder)
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.icon).tag(p)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                Section("Context Tags") {
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
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "Add" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 480, height: 450)
        .onAppear {
            if let item {
                name = item.name
                category = item.category ?? ""
                priority = item.priority
                notes = item.notes ?? ""
                selectedTags = Set(item.contextTags)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        guard var template = store.templates.first(where: { $0.id == templateID }) else { return }

        let newItem = TemplateItem(
            id: item?.id ?? UUID(),
            name: trimmedName,
            category: category.isEmpty ? nil : category,
            contextTags: Array(selectedTags).sorted(),
            priority: priority,
            notes: notes.isEmpty ? nil : notes
        )

        if let existingID = item?.id, let idx = template.items.firstIndex(where: { $0.id == existingID }) {
            template.items[idx] = newItem
        } else {
            template.items.append(newItem)
        }

        store.updateTemplate(template)
        dismiss()
    }
}
