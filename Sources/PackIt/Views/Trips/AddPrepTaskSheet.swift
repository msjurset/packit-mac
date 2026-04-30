import SwiftUI
import PackItKit

struct AddPrepTaskSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripID: UUID
    let departureDate: Date
    let returnDate: Date?

    @State private var name = ""
    @State private var category = ""
    @State private var timing: PrepTaskTiming = .daysBefore
    @State private var notes = ""

    var body: some View {
        FormSheet(width: 420, height: 340) {
            LeadingTextField(label: "Task", text: $name, prompt: "e.g. Stop mail delivery")
            PrepCategoryField(text: $category)
            Picker("Timing", selection: $timing) {
                ForEach(PrepTaskTiming.allCases, id: \.self) { t in
                    Label(t.label, systemImage: t.icon).tag(t)
                }
            }
            LeadingTextField(label: "Notes", text: $notes, prompt: "Optional details")
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Add") {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                store.addPrepTask(
                    to: tripID,
                    name: trimmed,
                    category: category.isEmpty ? nil : category,
                    timing: timing,
                    notes: notes.isEmpty ? nil : notes,
                    departureDate: departureDate,
                    returnDate: returnDate
                )
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
