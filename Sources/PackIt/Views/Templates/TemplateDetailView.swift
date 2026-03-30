import SwiftUI

struct TemplateDetailView: View {
    @Environment(PackItStore.self) private var store
    let template: PackingTemplate
    @State private var showEditSheet = false
    @State private var showAddItemSheet = false
    @State private var editingItem: TemplateItem?

    var body: some View {
        List {
            Section {
                LabeledContent("Items", value: "\(template.itemCount)")
                if !template.contextTags.isEmpty {
                    LabeledContent("Tags") {
                        HStack(spacing: 4) {
                            ForEach(template.contextTags, id: \.self) { tag in
                                StyledTag(name: tag)
                            }
                        }
                    }
                }
                if !template.categories.isEmpty {
                    LabeledContent("Categories", value: template.categories.joined(separator: ", "))
                }
                LabeledContent("Updated", value: template.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            let grouped = Dictionary(grouping: template.items, by: { $0.category ?? "Uncategorized" })
            let sortedKeys = grouped.keys.sorted()

            ForEach(sortedKeys, id: \.self) { category in
                Section(category) {
                    ForEach(grouped[category] ?? []) { item in
                        TemplateItemRow(item: item)
                            .contextMenu {
                                Button("Edit") {
                                    editingItem = item
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    removeItem(item.id)
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showAddItemSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }

                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TemplateEditorSheet(template: template)
        }
        .sheet(isPresented: $showAddItemSheet) {
            TemplateItemEditorSheet(templateID: template.id, item: nil)
        }
        .sheet(item: $editingItem) { item in
            TemplateItemEditorSheet(templateID: template.id, item: item)
        }
    }

    private func removeItem(_ itemID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.items.removeAll { $0.id == itemID }
        store.updateTemplate(updated)
    }
}

struct TemplateItemRow: View {
    let item: TemplateItem

    var body: some View {
        HStack(spacing: 8) {
            PriorityBadge(priority: item.priority)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if !item.contextTags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(item.contextTags.prefix(2), id: \.self) { tag in
                        StyledTag(name: tag)
                    }
                }
            }
        }
    }
}
