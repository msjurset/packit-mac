import SwiftUI

struct ImportTemplateSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID

    @State private var selectedTemplateIDs: Set<UUID> = []
    @State private var selectedTags: Set<String> = []
    @State private var expandedTemplateID: UUID?

    private var trip: TripInstance? {
        store.trips.first { $0.id == tripID }
    }

    private var existingItemNames: Set<String> {
        Set((trip?.items ?? []).map { $0.name.lowercased() })
    }

    private var existingTaskNames: Set<String> {
        Set((trip?.prepTasks ?? []).map { $0.name.lowercased() })
    }

    private var previewCounts: (items: Int, tasks: Int, dupes: Int) {
        let sourceTemplates = store.templates.filter { selectedTemplateIDs.contains($0.id) }
        var newItems = 0
        var newTasks = 0
        var dupes = 0
        var seenItems = existingItemNames
        var seenTasks = existingTaskNames

        for template in sourceTemplates {
            let items: [TemplateItem] = selectedTags.isEmpty
                ? template.items
                : template.items.filter { $0.contextTags.isEmpty || $0.contextTags.contains(where: { selectedTags.contains($0) }) }
            for item in items {
                let key = item.name.lowercased()
                if seenItems.contains(key) {
                    dupes += 1
                } else {
                    seenItems.insert(key)
                    newItems += 1
                }
            }

            let tasks: [PrepTaskTemplate] = selectedTags.isEmpty
                ? template.prepTasks
                : template.prepTasks.filter { $0.contextTags.isEmpty || $0.contextTags.contains(where: { selectedTags.contains($0) }) }
            for task in tasks {
                let key = task.name.lowercased()
                if seenTasks.contains(key) {
                    dupes += 1
                } else {
                    seenTasks.insert(key)
                    newTasks += 1
                }
            }
        }
        return (newItems, newTasks, dupes)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Templates")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if store.templates.isEmpty {
                        Text("No templates available.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.templates) { template in
                            let alreadyUsed = trip?.sourceTemplateIDs.contains(template.id) ?? false
                            let isExpanded = expandedTemplateID == template.id

                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            expandedTemplateID = isExpanded ? nil : template.id
                                        }
                                    } label: {
                                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 12)
                                    }
                                    .buttonStyle(.plain)
                                    .focusable(false)

                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(template.name)
                                            if template.isComposite {
                                                Image(systemName: "link")
                                                    .font(.caption2)
                                                    .foregroundStyle(.packitTeal)
                                            }
                                            if alreadyUsed {
                                                Text("already imported")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        Text(importTemplateSummary(template))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        if selectedTemplateIDs.contains(template.id) {
                                            selectedTemplateIDs.remove(template.id)
                                        } else {
                                            selectedTemplateIDs.insert(template.id)
                                        }
                                    } label: {
                                        Image(systemName: selectedTemplateIDs.contains(template.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedTemplateIDs.contains(template.id) ? Color.packitTeal : Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .focusable(false)
                                }
                                .padding(.vertical, 6)

                                if isExpanded {
                                    VStack(alignment: .leading, spacing: 2) {
                                        if !template.items.isEmpty {
                                            let grouped = Dictionary(grouping: template.items, by: { $0.category ?? "Uncategorized" })
                                            ForEach(grouped.keys.sorted(), id: \.self) { cat in
                                                Text(cat)
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.top, 4)
                                                ForEach(grouped[cat] ?? []) { item in
                                                    HStack(spacing: 4) {
                                                        Text("·").foregroundStyle(.tertiary)
                                                        Text(item.name).font(.caption).foregroundStyle(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        if !template.prepTasks.isEmpty {
                                            Text("Prep Tasks")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 4)
                                            ForEach(template.prepTasks) { task in
                                                HStack(spacing: 4) {
                                                    Text("·").foregroundStyle(.tertiary)
                                                    Text(task.name).font(.caption).foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.leading, 20)
                                    .padding(.bottom, 4)
                                }

                                Divider()
                            }
                        }
                    }

                    if !store.allTagNames.isEmpty && !selectedTemplateIDs.isEmpty {
                        Text("Filter by Context Tags")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        Text("Only include items matching these tags (leave empty for all).")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
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
                .padding()
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if !selectedTemplateIDs.isEmpty {
                    let counts = previewCounts
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(counts.items) items, +\(counts.tasks) prep tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if counts.dupes > 0 {
                            Text("\(counts.dupes) duplicates will be skipped")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                Button("Import") {
                    store.importTemplates(
                        into: tripID,
                        templateIDs: Array(selectedTemplateIDs),
                        selectedTags: Array(selectedTags)
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTemplateIDs.isEmpty)
            }
            .padding()
        }
        .frame(width: 550, height: 500)
    }

    private func importTemplateSummary(_ template: PackingTemplate) -> String {
        var parts: [String] = []
        if template.itemCount > 0 { parts.append("\(template.itemCount) items") }
        if template.prepTaskCount > 0 { parts.append("\(template.prepTaskCount) prep") }
        if !template.procedures.isEmpty {
            let steps = template.procedures.reduce(0) { $0 + $1.stepCount }
            parts.append("\(template.procedures.count) procedures (\(steps) steps)")
        }
        if !template.referenceLinks.isEmpty { parts.append("\(template.referenceLinks.count) links") }
        if template.isComposite { parts.append("links \(template.linkedTemplateIDs.count) templates") }
        return parts.isEmpty ? "Empty" : parts.joined(separator: ", ")
    }
}
