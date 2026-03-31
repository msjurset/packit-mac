import SwiftUI

struct TemplateDetailView: View {
    @Environment(PackItStore.self) private var store
    let template: PackingTemplate
    @State private var showEditSheet = false
    @State private var showAddItemSheet = false
    @State private var editingItem: TemplateItem?

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

                    if !template.contextTags.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(template.contextTags, id: \.self) { tag in
                                StyledTag(name: tag)
                            }
                        }
                    }

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
        .navigationTitle("Template")
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
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
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
