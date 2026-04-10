import SwiftUI

struct ProcedureEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let templateID: UUID
    let procedure: ProcedureTemplate?

    @State private var name = ""
    @State private var phase: ProcedurePhase = .beforeDeparture
    @State private var steps: [EditableStep] = []
    @State private var newStepText = ""
    @State private var newStepOrder = ""
    @FocusState private var newStepFocused: Bool

    private var isNew: Bool { procedure == nil }

    struct EditableStep: Identifiable {
        let id: UUID
        var text: String
        var notes: String
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Form {
                Section("Procedure Details") {
                    LeadingTextField(label: "Name", text: $name, prompt: "e.g. Before Travel RV Checklist")
                    Picker("Phase", selection: $phase) {
                        ForEach(ProcedurePhase.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.icon).tag(p)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 140)

            Divider()

            // Steps list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Steps (\(steps.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                List {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(index + 1).")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .frame(width: 20, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 2) {
                                TextField("Step description", text: $steps[index].text)
                                    .font(.callout)
                                TextField("Notes (optional)", text: $steps[index].notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                steps.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.6))
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { from, to in
                        steps.move(fromOffsets: from, toOffset: to)
                    }

                    // Add step inline with position field
                    HStack(spacing: 8) {
                        TextField("#", text: $newStepOrder)
                            .font(.caption.monospacedDigit())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 32)
                        TextField("Add a step...", text: $newStepText)
                            .font(.callout)
                            .focused($newStepFocused)
                            .onSubmit { addStep() }
                        Button("Add") { addStep() }
                            .font(.caption)
                            .disabled(newStepText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                if !isNew {
                    Spacer()
                    Button(role: .destructive) { deleteProcedure() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                Spacer()
                Button(isNew ? "Add" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || steps.isEmpty)
            }
            .padding()
        }
        .frame(width: 550, height: 550)
        .onAppear {
            if let procedure {
                name = procedure.name
                phase = procedure.phase
                steps = procedure.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
                    EditableStep(id: $0.id, text: $0.text, notes: $0.notes ?? "")
                }
                newStepOrder = "\(steps.count + 1)"
            } else {
                newStepOrder = "1"
            }
        }
    }

    private func addStep() {
        let trimmed = newStepText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let targetPosition = max(1, Int(newStepOrder) ?? (steps.count + 1))
        let insertIndex = min(targetPosition - 1, steps.count)

        steps.insert(EditableStep(id: UUID(), text: trimmed, notes: ""), at: insertIndex)

        newStepText = ""
        newStepOrder = "\(steps.count + 1)"
        newStepFocused = true
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !steps.isEmpty else { return }
        guard var template = store.templates.first(where: { $0.id == templateID }) else { return }

        let procSteps = steps.enumerated().map { index, step in
            ProcedureStepTemplate(
                id: step.id,
                text: step.text,
                notes: step.notes.isEmpty ? nil : step.notes,
                sortOrder: index
            )
        }

        let newProc = ProcedureTemplate(
            id: procedure?.id ?? UUID(),
            name: trimmedName,
            phase: phase,
            steps: procSteps
        )

        if let existingID = procedure?.id, let idx = template.procedures.firstIndex(where: { $0.id == existingID }) {
            template.procedures[idx] = newProc
        } else {
            template.procedures.append(newProc)
        }

        store.updateTemplate(template)
        dismiss()
    }

    private func deleteProcedure() {
        guard let procID = procedure?.id,
              var template = store.templates.first(where: { $0.id == templateID }) else { return }
        template.procedures.removeAll { $0.id == procID }
        store.updateTemplate(template)
        dismiss()
    }
}
