import SwiftUI

struct TripDetailView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var activeSheet: TripSheet?
    @State private var pendingReminders = 0
    @State private var showInspector = true
    @State private var newTodoText = ""

    enum TripSheet: Identifiable {
        case edit
        case addItem
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
            }
            .padding(.vertical)
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
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

                Button { store.printTrip(trip) } label: {
                    Label("Print", systemImage: "printer")
                }
                .help("Print packing list")

                Button { activeSheet = .edit } label: {
                    Label("Edit Trip", systemImage: "pencil")
                }

                Button { showInspector.toggle() } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                        .foregroundStyle(showInspector ? .packitTeal : .secondary)
                }
                .help("Toggle TODOs & Notes")
            }
        }
        .inspector(isPresented: $showInspector) {
            TripInspectorView(trip: trip, activeSheet: $activeSheet, pendingReminders: pendingReminders)
                .inspectorColumnWidth(min: 250, ideal: 300, max: 380)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                TripEditorSheet(trip: trip)
            case .addItem:
                AddTripItemSheet(tripID: trip.id)
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

                if trip.isDepartureSoon && trip.status == .active {
                    Label("Departure is soon!", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            Spacer()
            progressRing
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

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 6) {
            Menu {
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
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Actions")

            Button { store.printTrip(trip) } label: {
                Image(systemName: "printer")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Print packing list")

            Button { activeSheet = .edit } label: {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit trip")

            Button { showInspector.toggle() } label: {
                Image(systemName: "sidebar.trailing")
                    .font(.title3)
                    .foregroundStyle(showInspector ? .packitTeal : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle TODOs & Notes")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.06))
        .clipShape(Capsule())
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

            ForEach(Array(sortedKeys.enumerated()), id: \.element) { index, category in
                CategorySection(category: category, items: grouped[category] ?? [], tripID: trip.id, isAlternate: index.isMultiple(of: 2))
            }
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

// MARK: - Category Section

struct CategorySection: View {
    let category: String
    let items: [TripItem]
    let tripID: UUID
    var isAlternate: Bool = false

    private var packedCount: Int { items.filter(\.isPacked).count }
    private let columns = [GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 4, alignment: .top)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: CategoryIcon.icon(for: category))
                    .font(.system(size: 11))
                    .foregroundStyle(CategoryIcon.color(for: category))
                    .frame(width: 15)
                Text(category.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(packedCount)/\(items.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(packedCount == items.count ? Color.packitGreen : Color.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    PackingItemRow(item: item, tripID: tripID)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(isAlternate ? Color.secondary.opacity(0.04) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Inspector View

struct TripInspectorView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @Binding var activeSheet: TripDetailView.TripSheet?
    let pendingReminders: Int
    @State private var newTodoText = ""
    @State private var isEditingNotes = false
    @State private var editedNotes = ""
    @FocusState private var todoFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // TODOs
                todoSection

                Divider()

                // Notes
                notesSection

                Divider()

                // Trip Info
                infoSection
            }
            .padding()
        }
    }

    // MARK: - TODOs

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("TODOs", systemImage: "checklist")
                .font(.headline)

            // Quick-add field
            HStack(spacing: 8) {
                TextField("Add a todo...", text: $newTodoText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($todoFieldFocused)
                    .onSubmit { addTodo() }
                    .padding(8)
                    .background(.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.packitTeal)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if trip.todos.isEmpty {
                Text("No TODOs yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(trip.todos) { todo in
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    store.toggleTodo(tripID: trip.id, todoID: todo.id)
                                }
                            } label: {
                                Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(todo.isComplete ? .packitGreen : .secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(todo.text)
                                    .font(.callout)
                                    .strikethrough(todo.isComplete)
                                    .foregroundStyle(todo.isComplete ? .secondary : .primary)
                                    .lineLimit(2)

                                if let due = todo.dueDate {
                                    Text(due.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(todo.isOverdue ? Color.packitRed : Color.secondary)
                                }
                            }

                            Spacer()

                            PriorityBadge(priority: todo.priority)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.removeTodo(from: trip.id, todoID: todo.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Summary
            if !trip.todos.isEmpty {
                let done = trip.todos.filter(\.isComplete).count
                Text("\(done)/\(trip.todos.count) complete")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTodo(to: trip.id, text: trimmed, dueDate: nil, priority: .medium)
        newTodoText = ""
        todoFieldFocused = true
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)
                Spacer()
                if isEditingNotes {
                    Button("Done") { saveNotes() }
                        .font(.caption)
                        .foregroundStyle(.packitTeal)
                } else {
                    Button("Edit") {
                        editedNotes = trip.scratchNotes
                        isEditingNotes = true
                    }
                    .font(.caption)
                    .foregroundStyle(.packitTeal)
                }
            }

            if isEditingNotes {
                TextEditor(text: $editedNotes)
                    .font(.callout)
                    .frame(minHeight: 100, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
            } else {
                Text(trip.scratchNotes.isEmpty ? "No notes yet..." : trip.scratchNotes)
                    .font(.callout)
                    .foregroundStyle(trip.scratchNotes.isEmpty ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.secondary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        editedNotes = trip.scratchNotes
                        isEditingNotes = true
                    }
            }
        }
    }

    private func saveNotes() {
        var updated = trip
        updated.scratchNotes = editedNotes
        store.updateTrip(updated)
        isEditingNotes = false
    }

    // MARK: - Trip Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Trip Info", systemImage: "info.circle")
                .font(.headline)

            VStack(spacing: 6) {
                infoRow(icon: "airplane.departure", label: "Departure", value: trip.departureDate.formatted(date: .long, time: .omitted))
                if let ret = trip.returnDate {
                    infoRow(icon: "airplane.arrival", label: "Return", value: ret.formatted(date: .long, time: .omitted))
                }
                infoRow(icon: "suitcase", label: "Status", value: trip.status.label)
                infoRow(icon: "number", label: "Items", value: "\(trip.totalItems)")
                if pendingReminders > 0 {
                    infoRow(icon: "bell.fill", label: "Reminders", value: "\(pendingReminders)")
                }
                if !trip.adHocItems.isEmpty {
                    infoRow(icon: "sparkles", label: "New Items", value: "\(trip.adHocItems.count)")
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.packitTeal)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Notes Editor Sheet (kept as fallback)

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
