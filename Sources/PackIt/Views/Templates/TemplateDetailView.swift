import SwiftUI

struct TemplateDetailView: View {
    @Environment(PackItStore.self) private var store
    let template: PackingTemplate
    @State private var showEditSheet = false
    @State private var showAddItemSheet = false
    @State private var showExportSheet = false
    @State private var editingItem: TemplateItem?
    @State private var isAddingTag = false
    @State private var newTagText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(template.name)
                            .font(.title2.bold())
                        Spacer()
                        Text("\(template.itemCount) items")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    InlineTagEditor(
                        tags: template.contextTags,
                        isAddingTag: $isAddingTag,
                        newTagText: $newTagText,
                        onAdd: { tagName in addTagToTemplate(tagName) },
                        onRemove: { tagName in removeTagFromTemplate(tagName) }
                    )

                    HStack(spacing: 20) {
                        if !template.categories.isEmpty {
                            Label("\(template.categories.count) categories", systemImage: "folder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Label("Updated \(template.updatedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Add item button
                Button {
                    showAddItemSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)

                // Items by category
                let grouped = Dictionary(grouping: template.items, by: { $0.category ?? "Uncategorized" })
                let sortedKeys = grouped.keys.sorted()

                ForEach(sortedKeys, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(category.uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(grouped[category]?.count ?? 0)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.leading, 4)

                        VStack(spacing: 1) {
                            ForEach(grouped[category] ?? []) { item in
                                TemplateItemRow(item: item)
                                    .onTapGesture(count: 2) { editingItem = item }
                                    .draggable(item.id.uuidString)
                                    .dropDestination(for: String.self) { droppedIDs, _ in
                                        guard let droppedID = droppedIDs.first,
                                              let draggedUUID = UUID(uuidString: droppedID) else { return false }
                                        store.moveTemplateItem(in: template.id, itemID: draggedUUID, before: item.id)
                                        return true
                                    }
                                    .contextMenu {
                                        Button {
                                            editingItem = item
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            removeItem(item.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("templateDetail")
        .navigationTitle("Template")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.duplicateTemplate(id: template.id)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }

                Button {
                    showExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
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
        .sheet(isPresented: $showExportSheet) {
            TemplateExportSheet(template: template)
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

    private func addTagToTemplate(_ tagName: String) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        guard !updated.contextTags.contains(tagName) else { return }
        updated.contextTags.append(tagName)
        store.updateTemplate(updated, actionName: "Add Tag")
        // Also register as a global tag if new
        if !store.tags.contains(where: { $0.name.lowercased() == tagName.lowercased() }) {
            store.addTag(name: tagName)
        }
    }

    private func removeTagFromTemplate(_ tagName: String) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.contextTags.removeAll { $0 == tagName }
        store.updateTemplate(updated, actionName: "Remove Tag")
    }
}

struct TemplateItemRow: View {
    let item: TemplateItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            PriorityBadge(priority: item.priority)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name)
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.packitTeal)
                    }
                }
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if !item.contextTags.isEmpty {
                HStack(spacing: 3) {
                    ForEach(item.contextTags.prefix(2), id: \.self) { tag in
                        StyledTag(name: tag, compact: true)
                    }
                    if item.contextTags.count > 2 {
                        Text("+\(item.contextTags.count - 2)")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(isHovered ? Color.primary.opacity(0.03) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
