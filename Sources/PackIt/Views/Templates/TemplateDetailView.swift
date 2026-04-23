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
    @State private var showAddPrepTaskSheet = false
    @State private var editingPrepTask: PrepTaskTemplate?
    @State private var showAddProcedureSheet = false
    @State private var editingProcedure: ProcedureTemplate?
    @State private var showAddRefLink = false
    @State private var newRefLinkLabel = ""
    @State private var newRefLinkURL = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(template.name)
                            .font(.title2.bold())
                        Spacer()
                        Text(templateDetailSummary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    if store.isReceivedShare(templateID: template.id) {
                        SharedBadge(author: template.createdBy)
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

                // Linked templates (composite)
                if !template.linkedTemplateIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Includes Templates", systemImage: "link")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        FlowLayout(spacing: 4) {
                            ForEach(template.linkedTemplateIDs, id: \.self) { linkedID in
                                if let linked = store.templates.first(where: { $0.id == linkedID }) {
                                    HStack(spacing: 4) {
                                        Text(linked.name)
                                            .font(.caption)
                                        Text("\(linked.itemCount)")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        Button {
                                            removeLinkedTemplate(linkedID)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 7, weight: .bold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.08))
                                    .clipShape(Capsule())
                                }
                            }
                            Menu {
                                ForEach(store.templates.filter { $0.id != template.id && !template.linkedTemplateIDs.contains($0.id) }) { t in
                                    Button(t.name) { addLinkedTemplate(t.id) }
                                }
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.packitTeal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

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
                // Prep Tasks
                if !template.prepTasks.isEmpty || true {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Prep Tasks", systemImage: "checklist")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddPrepTaskSheet = true
                            } label: {
                                Label("Add Prep Task", systemImage: "plus.circle.fill")
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(.packitTeal)
                            }
                            .buttonStyle(.plain)
                        }

                        if template.prepTasks.isEmpty {
                            Text("No prep tasks yet. Add tasks like \"Stop mail\" or \"Set light timers\" that should happen before or after your trip.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 8)
                        } else {
                            let grouped = Dictionary(grouping: template.prepTasks, by: \.timing)
                            FlowLayout(spacing: 8) {
                                ForEach(PrepTaskTiming.allCases, id: \.self) { timing in
                                    if let tasks = grouped[timing], !tasks.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Label(timing.label, systemImage: timing.icon)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)

                                            ForEach(tasks) { task in
                                                HStack(spacing: 6) {
                                                    if let cat = task.category {
                                                        Text(cat)
                                                            .font(.system(size: 9).weight(.medium))
                                                            .padding(.horizontal, 5)
                                                            .padding(.vertical, 1)
                                                            .background(.secondary.opacity(0.08))
                                                            .clipShape(Capsule())
                                                    }
                                                    Text(task.name)
                                                        .font(.callout)
                                                }
                                                .onTapGesture(count: 2) { editingPrepTask = task }
                                                .contextMenu {
                                                    Button { editingPrepTask = task } label: {
                                                        Label("Edit", systemImage: "pencil")
                                                    }
                                                    Divider()
                                                    Button(role: .destructive) { removePrepTask(task.id) } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .background(.secondary.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                // Procedures
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Procedures", systemImage: "list.number")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAddProcedureSheet = true
                        } label: {
                            Label("Add Procedure", systemImage: "plus.circle.fill")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.packitTeal)
                        }
                        .buttonStyle(.plain)
                    }

                    if template.procedures.isEmpty {
                        Text("No procedures yet. Add step-by-step procedures like \"Before Departure\" or \"Site Setup\".")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(template.procedures) { proc in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: proc.phase.icon)
                                        .font(.caption)
                                        .foregroundStyle(.packitTeal)
                                    Text(proc.name)
                                        .font(.callout.weight(.semibold))
                                    Text(proc.phase.label)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                    Button { editingProcedure = proc } label: {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundStyle(.packitTeal)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Edit procedure")
                                    Text("\(proc.stepCount) steps")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                ForEach(proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder })) { step in
                                    HStack(spacing: 6) {
                                        Text("\(step.sortOrder + 1).")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 18, alignment: .trailing)
                                        Text(step.text)
                                            .font(.caption)
                                        if let notes = step.notes, !notes.isEmpty {
                                            Text(notes)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                            .padding(10)
                            .background(.secondary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture(count: 2) { editingProcedure = proc }
                            .contextMenu {
                                Button { editingProcedure = proc } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) { removeProcedure(proc.id) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)

                // Reference Links
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Reference Links", systemImage: "link")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAddRefLink.toggle()
                            newRefLinkLabel = ""
                            newRefLinkURL = ""
                        } label: {
                            Label("Add Link", systemImage: "plus.circle.fill")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.packitTeal)
                        }
                        .buttonStyle(.plain)
                    }

                    if showAddRefLink {
                        HStack(spacing: 6) {
                            TextField("Label", text: $newRefLinkLabel)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            TextField("URL", text: $newRefLinkURL)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { addRefLink() }
                            Button("Add") { addRefLink() }
                                .disabled(newRefLinkLabel.isEmpty || newRefLinkURL.isEmpty)
                        }
                    }

                    if template.referenceLinks.isEmpty && !showAddRefLink {
                        Text("Add useful links that should carry through to trips.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(template.referenceLinks) { link in
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                                    .foregroundStyle(.packitTeal)
                                Text(link.label)
                                    .font(.callout)
                                Text(link.url)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                Spacer()
                                Button {
                                    removeRefLink(link.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .accessibilityIdentifier("templateDetail")
        .navigationTitle("Template")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(store.templates.filter { $0.id != template.id && !template.linkedTemplateIDs.contains($0.id) }) { t in
                        Button { addLinkedTemplate(t.id) } label: {
                            Label(t.name, systemImage: "doc.on.doc")
                        }
                    }
                } label: {
                    Label("Link Template", systemImage: "link.badge.plus")
                }
                .help("Include another template's items")

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
        .sheet(isPresented: $showAddPrepTaskSheet) {
            PrepTaskEditorSheet(templateID: template.id, task: nil)
        }
        .sheet(item: $editingPrepTask) { task in
            PrepTaskEditorSheet(templateID: template.id, task: task)
        }
        .sheet(isPresented: $showAddProcedureSheet) {
            ProcedureEditorSheet(templateID: template.id, procedure: nil)
        }
        .sheet(item: $editingProcedure) { proc in
            ProcedureEditorSheet(templateID: template.id, procedure: proc)
        }
    }

    private var templateDetailSummary: String {
        var parts: [String] = []
        if template.itemCount > 0 { parts.append("\(template.itemCount) items") }
        if template.prepTaskCount > 0 { parts.append("\(template.prepTaskCount) prep tasks") }
        if !template.procedures.isEmpty { parts.append("\(template.procedures.count) procedures") }
        return parts.isEmpty ? "Empty" : parts.joined(separator: " · ")
    }

    private func addLinkedTemplate(_ linkedID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        guard !updated.linkedTemplateIDs.contains(linkedID) else { return }
        updated.linkedTemplateIDs.append(linkedID)
        store.updateTemplate(updated)
    }

    private func removeLinkedTemplate(_ linkedID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.linkedTemplateIDs.removeAll { $0 == linkedID }
        store.updateTemplate(updated)
    }

    private func addRefLink() {
        guard !newRefLinkLabel.isEmpty, !newRefLinkURL.isEmpty else { return }
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        var url = newRefLinkURL
        if !url.contains("://") { url = "https://" + url }
        updated.referenceLinks.append(ReferenceLink(label: newRefLinkLabel, url: url))
        store.updateTemplate(updated)
        showAddRefLink = false
    }

    private func removeRefLink(_ linkID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.referenceLinks.removeAll { $0.id == linkID }
        store.updateTemplate(updated)
    }

    private func removeProcedure(_ procID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.procedures.removeAll { $0.id == procID }
        store.updateTemplate(updated)
    }

    private func removePrepTask(_ taskID: UUID) {
        guard var updated = store.templates.first(where: { $0.id == template.id }) else { return }
        updated.prepTasks.removeAll { $0.id == taskID }
        store.updateTemplate(updated)
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
                    if let owner = item.owner, !owner.isEmpty {
                        Text(owner)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.indigo.opacity(0.12))
                            .foregroundStyle(.indigo)
                            .clipShape(Capsule())
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
