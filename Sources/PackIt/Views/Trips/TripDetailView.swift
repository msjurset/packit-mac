import SwiftUI

struct TripDetailView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var activeSheet: TripSheet?
    @State private var pendingReminders = 0
    @State private var showDeleteConfirm = false

    enum TripSheet: Identifiable {
        case edit
        case addItem
        case addTodo
        case editNotes
        case merge
        case export

        var id: String { String(describing: self) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                tripHeader
                    .padding(.horizontal)

                if !trip.overdueItems.isEmpty {
                    overdueSection
                        .padding(.horizontal)
                }

                packingSection
                    .padding(.horizontal)

                todoSection
                    .padding(.horizontal)

                notesSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Section {
                        Button { activeSheet = .addItem } label: {
                            Label("Add Item", systemImage: "plus.circle")
                        }
                        Button { activeSheet = .addTodo } label: {
                            Label("Add Todo", systemImage: "checklist")
                        }
                        Button { activeSheet = .editNotes } label: {
                            Label("Edit Notes", systemImage: "note.text")
                        }
                    }
                    Section("Status") {
                        statusMenuItems
                    }
                    Section {
                        if !trip.adHocItems.isEmpty {
                            Button { activeSheet = .merge } label: {
                                Label("Merge to Template...", systemImage: "arrow.up.doc")
                            }
                        }
                        Button { activeSheet = .export } label: {
                            Label("Export...", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }

                Button { activeSheet = .edit } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                TripEditorSheet(trip: trip)
            case .addItem:
                AddTripItemSheet(tripID: trip.id)
            case .addTodo:
                AddTodoSheet(tripID: trip.id)
            case .editNotes:
                NotesEditorSheet(trip: trip)
            case .merge:
                MergeToTemplateSheet(trip: trip)
            case .export:
                ExportSheet(trip: trip)
            }
        }
        .task {
            pendingReminders = await NotificationService.shared.pendingCount(for: trip.id)
        }
    }

    // MARK: - Header

    private var tripHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: trip.status.icon)
                            .foregroundStyle(Color.statusColor(trip.status))
                            .font(.title3)
                        Text(trip.status.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        Label(trip.departureDate.formatted(date: .long, time: .omitted), systemImage: "airplane.departure")
                        if let ret = trip.returnDate {
                            Label(ret.formatted(date: .long, time: .omitted), systemImage: "airplane.arrival")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if pendingReminders > 0 {
                        Label("\(pendingReminders) reminder\(pendingReminders == 1 ? "" : "s") set", systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(.packitTeal)
                    }
                }
                Spacer()
                progressRing
            }

            if trip.isDepartureSoon && trip.status == .active {
                Label("Departure is soon!", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var progressRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: trip.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: trip.progress)
                Text("\(Int(trip.progress * 100))%")
                    .font(.caption2.bold().monospacedDigit())
            }
            .frame(width: 52, height: 52)
            Text("\(trip.packedCount)/\(trip.totalItems)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var progressColor: Color {
        if trip.progress >= 1.0 { return .packitGreen }
        if trip.progress >= 0.5 { return .packitTeal }
        return .orange
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Needs Attention", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.packitRed)

            ForEach(trip.overdueItems) { item in
                HStack(spacing: 10) {
                    Button {
                        store.togglePacked(tripID: trip.id, itemID: item.id)
                    } label: {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(item.isPacked ? .packitGreen : .packitRed)
                    }
                    .buttonStyle(.plain)

                    Text(item.name)
                        .font(.callout.bold())
                    Spacer()
                    if let due = item.dueDate {
                        Text("Due " + due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.packitRed)
                    }
                }
                .padding(10)
                .background(.packitRed.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Packing Section

    private var packingSection: some View {
        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        let sortedKeys = grouped.keys.sorted()

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Packing List")
                    .font(.headline)
                Spacer()
                Button { activeSheet = .addItem } label: {
                    Label("Add Item", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.packitTeal)
            }

            ForEach(sortedKeys, id: \.self) { category in
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 2) {
                        ForEach(grouped[category] ?? []) { item in
                            PackingItemRow(item: item, tripID: trip.id)
                        }
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
                Button { activeSheet = .addTodo } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.packitTeal)
            }

            if trip.todos.isEmpty {
                Text("No TODOs yet.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                ForEach(trip.todos) { todo in
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.toggleTodo(tripID: trip.id, todoID: todo.id)
                            }
                        } label: {
                            Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.body)
                                .foregroundStyle(todo.isComplete ? .packitGreen : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(todo.text)
                            .strikethrough(todo.isComplete)
                            .foregroundStyle(todo.isComplete ? .secondary : .primary)

                        Spacer()

                        if let due = todo.dueDate {
                            Text(due.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(todo.isOverdue ? .packitRed : .secondary)
                        }

                        PriorityBadge(priority: todo.priority)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button { activeSheet = .editNotes } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.packitTeal)
            }
            Text(trip.scratchNotes.isEmpty ? "Tap Edit to add notes..." : trip.scratchNotes)
                .foregroundStyle(trip.scratchNotes.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Status Menu Items

    @ViewBuilder
    private var statusMenuItems: some View {
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
}

// MARK: - Notes Editor Sheet

struct NotesEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("Trip Notes")
                .font(.headline)
                .padding()

            TextEditor(text: $notes)
                .font(.body)
                .padding(.horizontal)
                .frame(minHeight: 200)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    var updated = trip
                    updated.scratchNotes = notes
                    store.updateTrip(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 350)
        .onAppear { notes = trip.scratchNotes }
    }
}
