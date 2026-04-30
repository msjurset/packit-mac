import SwiftUI
import PackItKit

struct AddTodoSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID

    @State private var text = ""
    @State private var hasDueDate = false
    @State private var dueDate: Date = .now
    @State private var priority: Priority = .medium

    var body: some View {
        FormSheet(width: 400, height: 300) {
            LeadingTextField(label: "Todo", text: $text)
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { p in
                    Label(p.label, systemImage: p.icon).tag(p)
                }
            }
            Toggle("Due Date", isOn: $hasDueDate)
            if hasDueDate {
                LabeledContent("Due") {
                    HStack(spacing: 6) {
                        StepperDateField(selection: $dueDate)
                        CalendarPopoverButton(selection: $dueDate)
                    }
                }
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Add Todo") {
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                store.addTodo(
                    to: tripID,
                    text: trimmed,
                    dueDate: hasDueDate ? dueDate : nil,
                    priority: priority
                )
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
