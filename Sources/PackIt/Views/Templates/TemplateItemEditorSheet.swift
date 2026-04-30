import SwiftUI
import PackItKit

struct TemplateItemEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let templateID: UUID
    let item: TemplateItem?

    @State private var name = ""
    @State private var category = ""
    @State private var owner = ""
    @State private var priority: Priority = .medium
    @State private var quantity = 1
    @State private var notes = ""
    @State private var selectedTags: Set<String> = []

    private var isNew: Bool { item == nil }

    private var existingNames: Set<String> {
        guard let template = store.templates.first(where: { $0.id == templateID }) else { return [] }
        return Set(template.items.map(\.name))
    }

    var body: some View {
        FormSheet(width: 500, height: 550) {
            Section("Item Details") {
                ItemSuggestField(
                    text: $name,
                    excludeNames: existingNames
                ) { accepted in
                    if let source = store.templateItem(named: accepted) {
                        if category.isEmpty, let cat = source.category { category = cat }
                        if owner.isEmpty, let own = source.owner { owner = own }
                        priority = source.priority
                        selectedTags = Set(source.contextTags)
                        if notes.isEmpty, let n = source.notes { notes = n }
                        if quantity == 1 && source.quantity > 1 { quantity = source.quantity }
                    }
                }
                CategoryField(text: $category)
                OwnerField(text: $owner)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Label(p.label, systemImage: p.icon).tag(p)
                    }
                }
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
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
                TagSuggestField(selectedTags: selectedTags) { tags in
                    for tag in tags {
                        store.addTag(name: tag)
                        selectedTags.insert(tag)
                    }
                }
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            ContextualHelpButton(topic: .templateItems)
            if !isNew {
                Spacer()
                Button(role: .destructive) { deleteItem() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Spacer()
            Button(isNew ? "Add" : "Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            if let item {
                name = item.name
                category = item.category ?? ""
                owner = item.owner ?? ""
                priority = item.priority
                quantity = item.quantity
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
            owner: owner.isEmpty ? nil : owner,
            contextTags: Array(selectedTags).sorted(),
            priority: priority,
            notes: notes.isEmpty ? nil : notes,
            quantity: quantity
        )

        if let existingID = item?.id, let idx = template.items.firstIndex(where: { $0.id == existingID }) {
            template.items[idx] = newItem
        } else {
            template.items.append(newItem)
        }

        store.updateTemplate(template)
        dismiss()
    }

    private func deleteItem() {
        guard let itemID = item?.id,
              var template = store.templates.first(where: { $0.id == templateID }) else { return }
        template.items.removeAll { $0.id == itemID }
        store.updateTemplate(template)
        dismiss()
    }
}
