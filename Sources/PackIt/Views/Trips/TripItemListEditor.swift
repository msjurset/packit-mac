import SwiftUI

struct TripItemListEditor: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID
    var isReview: Bool = false

    @State private var excludedItemIDs: Set<UUID> = []
    @State private var excludedPrepTaskIDs: Set<UUID> = []
    @State private var excludedProcedureIDs: Set<UUID> = []
    @State private var excludedLinkIDs: Set<UUID> = []
    @State private var showImportTemplate = false
    @State private var preImportItemIDs: Set<UUID> = []
    @State private var preImportPrepTaskIDs: Set<UUID> = []
    @State private var preImportProcedureIDs: Set<UUID> = []
    @State private var preImportLinkIDs: Set<UUID> = []

    private var trip: TripInstance? {
        store.trips.first { $0.id == tripID }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isReview ? "Review Trip List" : "Edit Trip List")
                    .font(.headline)
                Spacer()
                if let trip {
                    Text(keepingSummary(trip))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Two-column layout
            if let trip {
                HStack(alignment: .top, spacing: 0) {
                    // Left: Prep tasks + Procedures + Links
                    if !trip.prepTasks.isEmpty || !trip.procedures.isEmpty || !trip.referenceLinks.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                // Prep tasks
                                if !trip.prepTasks.isEmpty {
                                    Text("Prep Tasks")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    ForEach(PrepTaskTiming.allCases, id: \.self) { timing in
                                        let tasks = trip.prepTasks.filter { $0.timing == timing }
                                        if !tasks.isEmpty {
                                            Text(timing.label)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.tertiary)
                                                .padding(.top, 4)
                                            ForEach(tasks) { task in
                                                PrepTaskEditorRow(
                                                    task: task,
                                                    isExcluded: excludedPrepTaskIDs.contains(task.id),
                                                    toggle: { togglePrepTask(task.id) }
                                                )
                                            }
                                        }
                                    }
                                }

                                // Procedures
                                if !trip.procedures.isEmpty {
                                    Divider()
                                    Text("Procedures")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    ForEach(trip.procedures) { proc in
                                        HStack(spacing: 8) {
                                            Button {
                                                if excludedProcedureIDs.contains(proc.id) {
                                                    excludedProcedureIDs.remove(proc.id)
                                                } else {
                                                    excludedProcedureIDs.insert(proc.id)
                                                }
                                            } label: {
                                                Image(systemName: excludedProcedureIDs.contains(proc.id) ? "square" : "checkmark.square.fill")
                                                    .foregroundColor(excludedProcedureIDs.contains(proc.id) ? .gray : .packitTeal)
                                            }
                                            .buttonStyle(.plain)

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(proc.name)
                                                    .font(.callout)
                                                    .strikethrough(excludedProcedureIDs.contains(proc.id))
                                                    .foregroundStyle(excludedProcedureIDs.contains(proc.id) ? .tertiary : .primary)
                                                Text("\(proc.steps.count) steps · \(proc.phase.label)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        .opacity(excludedProcedureIDs.contains(proc.id) ? 0.5 : 1)
                                    }
                                }

                                // Reference Links
                                if !trip.referenceLinks.isEmpty {
                                    Divider()
                                    Text("Reference Links")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    ForEach(trip.referenceLinks) { link in
                                        HStack(spacing: 8) {
                                            Button {
                                                if excludedLinkIDs.contains(link.id) {
                                                    excludedLinkIDs.remove(link.id)
                                                } else {
                                                    excludedLinkIDs.insert(link.id)
                                                }
                                            } label: {
                                                Image(systemName: excludedLinkIDs.contains(link.id) ? "square" : "checkmark.square.fill")
                                                    .foregroundColor(excludedLinkIDs.contains(link.id) ? .gray : .packitTeal)
                                            }
                                            .buttonStyle(.plain)

                                            Text(link.label)
                                                .font(.callout)
                                                .strikethrough(excludedLinkIDs.contains(link.id))
                                                .foregroundStyle(excludedLinkIDs.contains(link.id) ? .tertiary : .primary)
                                        }
                                        .opacity(excludedLinkIDs.contains(link.id) ? 0.5 : 1)
                                    }
                                }
                            }
                            .padding(12)
                        }
                        .frame(width: 280)

                        Divider()
                    }

                    // Right: Packing items in two columns
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Packing Items")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
                        let sortedKeys = grouped.keys.sorted()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(sortedKeys.enumerated()), id: \.element) { index, category in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .padding(.top, 8)
                                            .padding(.horizontal, 12)

                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 2) {
                                            ForEach(grouped[category] ?? []) { item in
                                                ItemEditorRow(
                                                    item: item,
                                                    isExcluded: excludedItemIDs.contains(item.id),
                                                    toggle: { toggleItem(item.id) }
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.bottom, 6)
                                    }
                                    .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.04) : .clear)
                                }
                            }
                            .padding(.bottom, 12)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Button {
                    // Snapshot current IDs before import
                    if let trip {
                        preImportItemIDs = Set(trip.items.map(\.id))
                        preImportPrepTaskIDs = Set(trip.prepTasks.map(\.id))
                        preImportProcedureIDs = Set(trip.procedures.map(\.id))
                        preImportLinkIDs = Set(trip.referenceLinks.map(\.id))
                    }
                    showImportTemplate = true
                } label: {
                    Label("Add from Template", systemImage: "arrow.down.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if !excludedItemIDs.isEmpty || !excludedPrepTaskIDs.isEmpty || !excludedProcedureIDs.isEmpty || !excludedLinkIDs.isEmpty {
                    let total = excludedItemIDs.count + excludedPrepTaskIDs.count + excludedProcedureIDs.count + excludedLinkIDs.count
                    Text("\(total) will be removed")
                        .font(.caption)
                        .foregroundStyle(.packitRed)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: (trip?.prepTasks.isEmpty == false || trip?.procedures.isEmpty == false || trip?.referenceLinks.isEmpty == false) ? 850 : 550, height: 600)
        .sheet(isPresented: $showImportTemplate, onDismiss: {
            // In edit mode (not review), mark newly imported content as unchecked
            guard !isReview, let trip else { return }
            if !preImportItemIDs.isEmpty {
                excludedItemIDs.formUnion(Set(trip.items.map(\.id)).subtracting(preImportItemIDs))
            }
            if !preImportPrepTaskIDs.isEmpty {
                excludedPrepTaskIDs.formUnion(Set(trip.prepTasks.map(\.id)).subtracting(preImportPrepTaskIDs))
            }
            if !preImportProcedureIDs.isEmpty {
                excludedProcedureIDs.formUnion(Set(trip.procedures.map(\.id)).subtracting(preImportProcedureIDs))
            }
            if !preImportLinkIDs.isEmpty {
                excludedLinkIDs.formUnion(Set(trip.referenceLinks.map(\.id)).subtracting(preImportLinkIDs))
            }
        }) {
            ImportTemplateSheet(tripID: tripID)
        }
    }

    private func keepingSummary(_ trip: TripInstance) -> String {
        var parts: [String] = []
        parts.append("\(trip.items.count - excludedItemIDs.count) items")
        if !trip.prepTasks.isEmpty { parts.append("\(trip.prepTasks.count - excludedPrepTaskIDs.count) prep") }
        if !trip.procedures.isEmpty { parts.append("\(trip.procedures.count - excludedProcedureIDs.count) procedures") }
        if !trip.referenceLinks.isEmpty { parts.append("\(trip.referenceLinks.count - excludedLinkIDs.count) links") }
        return "Keeping " + parts.joined(separator: ", ")
    }

    private func toggleItem(_ id: UUID) {
        if excludedItemIDs.contains(id) {
            excludedItemIDs.remove(id)
        } else {
            excludedItemIDs.insert(id)
        }
    }

    private func togglePrepTask(_ id: UUID) {
        if excludedPrepTaskIDs.contains(id) {
            excludedPrepTaskIDs.remove(id)
        } else {
            excludedPrepTaskIDs.insert(id)
        }
    }

    private func save() {
        store.bulkRemoveFromTrip(
            tripID,
            itemIDs: excludedItemIDs,
            prepTaskIDs: excludedPrepTaskIDs,
            procedureIDs: excludedProcedureIDs,
            referenceLinkIDs: excludedLinkIDs
        )
        dismiss()
    }
}

private struct ItemEditorRow: View {
    let item: TripItem
    let isExcluded: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                Image(systemName: isExcluded ? "square" : "checkmark.square.fill")
                    .foregroundColor(isExcluded ? .gray : .packitTeal)
                    .font(.body)
            }
            .buttonStyle(.plain)

            PriorityBadge(priority: item.priority)

            Text(item.name)
                .font(.callout)
                .strikethrough(isExcluded)
                .foregroundStyle(isExcluded ? .tertiary : .primary)

            Spacer()

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundColor(isExcluded ? .gray : .packitTeal)
            }
        }
        .opacity(isExcluded ? 0.5 : 1)
    }
}

private struct PrepTaskEditorRow: View {
    let task: PrepTask
    let isExcluded: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                Image(systemName: isExcluded ? "square" : "checkmark.square.fill")
                    .foregroundColor(isExcluded ? .gray : .packitTeal)
                    .font(.body)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.name)
                    .font(.callout)
                    .strikethrough(isExcluded)
                    .foregroundStyle(isExcluded ? .tertiary : .primary)
                if let cat = task.category {
                    Text(cat)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .opacity(isExcluded ? 0.5 : 1)
    }
}
