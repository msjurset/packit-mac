import SwiftUI
import PackItKit

struct PrepTaskEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let templateID: UUID
    let task: PrepTaskTemplate?

    @State private var name = ""
    @State private var category = ""
    @State private var timing: PrepTaskTiming = .daysBefore
    @State private var notes = ""
    @State private var selectedTags: Set<String> = []

    private var isNew: Bool { task == nil }

    var body: some View {
        FormSheet(width: 480, height: 450) {
            Section("Prep Task") {
                LeadingTextField(label: "Name", text: $name, prompt: "e.g. Stop mail delivery")
                PrepCategoryField(text: $category)
                Picker("Timing", selection: $timing) {
                    ForEach(PrepTaskTiming.allCases, id: \.self) { t in
                        Label(t.label, systemImage: t.icon).tag(t)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 50)
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
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            if !isNew {
                Spacer()
                Button(role: .destructive) { deleteTask() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Spacer()
            Button(isNew ? "Add" : "Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            if let task {
                name = task.name
                category = task.category ?? ""
                timing = task.timing
                notes = task.notes ?? ""
                selectedTags = Set(task.contextTags)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        guard var template = store.templates.first(where: { $0.id == templateID }) else { return }

        let newTask = PrepTaskTemplate(
            id: task?.id ?? UUID(),
            name: trimmedName,
            category: category.isEmpty ? nil : category,
            timing: timing,
            contextTags: Array(selectedTags).sorted(),
            notes: notes.isEmpty ? nil : notes
        )

        if let existingID = task?.id, let idx = template.prepTasks.firstIndex(where: { $0.id == existingID }) {
            template.prepTasks[idx] = newTask
        } else {
            template.prepTasks.append(newTask)
        }

        store.updateTemplate(template)
        dismiss()
    }

    private func deleteTask() {
        guard let taskID = task?.id,
              var template = store.templates.first(where: { $0.id == templateID }) else { return }
        template.prepTasks.removeAll { $0.id == taskID }
        store.updateTemplate(template)
        dismiss()
    }
}

/// Category field for prep tasks with auto-suggest from allPrepTaskCategories.
struct PrepCategoryField: View {
    @Environment(PackItStore.self) private var store
    @Binding var text: String

    @State private var isFocused = false
    @State private var state = SuggestState()
    @State private var eventMonitor: Any?

    private var filteredSuggestions: [String] {
        let query = text.lowercased()
        guard !query.isEmpty else { return store.allPrepTaskCategories }
        return store.allPrepTaskCategories.filter {
            $0.lowercased().contains(query) && $0.lowercased() != query
        }
    }

    private var displayed: [String] {
        state.displayedSuggestions(from: filteredSuggestions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LeadingTextField(label: "Category", text: $text, prompt: "e.g. Home, Supplies", isFocused: $isFocused)
                .onChange(of: text) { state.handleTextChange() }
                .onChange(of: isFocused) {
                    if isFocused {
                        SuggestMonitor.install(
                            monitor: &eventMonitor,
                            isFocused: { [isFocused] in isFocused },
                            state: state,
                            filteredSuggestions: { [self] in filteredSuggestions },
                            displayedSuggestions: { [self] in displayed },
                            advance: { [self] delta in
                                state.advanceSelection(by: delta, in: filteredSuggestions) { preview in
                                    state.isPreviewing = true
                                    text = preview
                                }
                            },
                            accept: { [self] suggestion in
                                state.isPreviewing = true
                                text = suggestion
                                state.markAccepted()
                            }
                        )
                    } else {
                        SuggestMonitor.remove(monitor: &eventMonitor)
                        state.dismissSuggestions()
                    }
                }

            if isFocused && !displayed.isEmpty {
                SuggestionDropdown(items: displayed, selectedIndex: state.selectedIndex) { suggestion in
                    state.isPreviewing = true
                    text = suggestion
                    state.markAccepted()
                }
            }
        }
        .onDisappear { SuggestMonitor.remove(monitor: &eventMonitor) }
    }
}
