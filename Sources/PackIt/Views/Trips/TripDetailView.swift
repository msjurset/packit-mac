import SwiftUI

struct TripDetailView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var showEditSheet = false
    @State private var showAddItemSheet = false
    @State private var showAddTodoSheet = false
    @State private var showMergeSheet = false
    @State private var showExportSheet = false
    @State private var showNotesEditor = false
    @State private var pendingReminders = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                tripHeader
                    .padding(.horizontal)

                if !trip.overdueItems.isEmpty {
                    overdueSection
                        .padding(.horizontal)
                }

                packingSection
                    .padding(.horizontal)

                if !trip.todos.isEmpty || showAddTodoSheet {
                    todoSection
                        .padding(.horizontal)
                }

                if !trip.scratchNotes.isEmpty || showNotesEditor {
                    notesSection
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button { showAddItemSheet = true } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    Button { showAddTodoSheet = true } label: {
                        Label("Add Todo", systemImage: "checklist")
                    }
                    Button { showNotesEditor = true } label: {
                        Label("Edit Notes", systemImage: "note.text")
                    }
                    Divider()
                    statusMenu
                    Divider()
                    if trip.adHocItems.count > 0 {
                        Button { showMergeSheet = true } label: {
                            Label("Merge to Template...", systemImage: "arrow.up.doc")
                        }
                    }
                    Button { showExportSheet = true } label: {
                        Label("Export...", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }

                Button { showEditSheet = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TripEditorSheet(trip: trip)
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddTripItemSheet(tripID: trip.id)
        }
        .sheet(isPresented: $showAddTodoSheet) {
            AddTodoSheet(tripID: trip.id)
        }
        .sheet(isPresented: $showMergeSheet) {
            MergeToTemplateSheet(trip: trip)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(trip: trip)
        }
        .task {
            pendingReminders = await NotificationService.shared.pendingCount(for: trip.id)
        }
    }

    // MARK: - Header

    private var tripHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: trip.status.icon)
                            .foregroundStyle(statusColor)
                        Text(trip.status.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        Label(trip.departureDate.formatted(date: .long, time: .omitted), systemImage: "airplane.departure")
                        if let ret = trip.returnDate {
                            Label(ret.formatted(date: .long, time: .omitted), systemImage: "airplane.arrival")
                        }
                    }
                    .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(trip.packedCount) / \(trip.totalItems)")
                        .font(.title2.bold())
                    ProgressView(value: trip.progress)
                        .frame(width: 100)
                    Text("packed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if pendingReminders > 0 {
                Label("\(pendingReminders) reminder\(pendingReminders == 1 ? "" : "s") scheduled", systemImage: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            if trip.isDepartureSoon && trip.status == .active {
                Label("Departure is soon!", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.orange)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Overdue High-Priority Items", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)

            ForEach(trip.overdueItems) { item in
                HStack {
                    Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isPacked ? .green : .red)
                    Text(item.name)
                        .font(.callout.bold())
                    Spacer()
                    if let due = item.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(8)
                .background(.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Packing Section

    private var packingSection: some View {
        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        let sortedKeys = grouped.keys.sorted()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Packing List")
                .font(.headline)

            ForEach(sortedKeys, id: \.self) { category in
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    ForEach(grouped[category] ?? []) { item in
                        PackingItemRow(item: item, tripID: trip.id)
                    }
                }
            }
        }
    }

    // MARK: - Todo Section

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODOs")
                    .font(.headline)
                Spacer()
                Button {
                    showAddTodoSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }

            ForEach(trip.todos) { todo in
                HStack {
                    Button {
                        store.toggleTodo(tripID: trip.id, todoID: todo.id)
                    } label: {
                        Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(todo.isComplete ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(todo.text)
                        .strikethrough(todo.isComplete)
                        .foregroundStyle(todo.isComplete ? .secondary : .primary)

                    Spacer()

                    if let due = todo.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(todo.isOverdue ? .red : .secondary)
                    }

                    Image(systemName: todo.priority.icon)
                        .font(.caption)
                        .foregroundStyle(priorityColor(todo.priority))
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            Text(trip.scratchNotes.isEmpty ? "No notes yet." : trip.scratchNotes)
                .foregroundStyle(trip.scratchNotes.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onTapGesture { showNotesEditor = true }
        }
    }

    // MARK: - Status Menu

    @ViewBuilder
    private var statusMenu: some View {
        ForEach(TripStatus.allCases, id: \.self) { status in
            if status != trip.status {
                Button {
                    var updated = trip
                    updated.status = status
                    store.updateTrip(updated)
                } label: {
                    Label("Mark as \(status.label)", systemImage: status.icon)
                }
            }
        }
    }

    private var statusColor: Color {
        switch trip.status {
        case .planning: return .blue
        case .active: return .green
        case .completed: return .secondary
        case .archived: return .secondary
        }
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
