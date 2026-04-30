import SwiftUI
import PackItKit

struct ProcedureChecklistView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var addingStepToProcID: UUID?
    @State private var newStepText = ""
    @State private var newStepOrder = ""
    @State private var editingProcID: UUID?
    @State private var dropTargetStepID: UUID?
    @State private var editingStepID: UUID?
    @State private var editStepText = ""
    @State private var editStepNotes = ""

    var body: some View {
        if trip.procedures.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("No procedures yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Procedures are step-by-step workflows like \"Before Departure\", \"Site Setup\", or \"Getting Ready to Tow\". Add them to your templates.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(ProcedurePhase.allCases, id: \.self) { phase in
                        let procs = trip.procedures.filter { $0.phase == phase }
                        if !procs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: phase.icon)
                                        .font(.caption)
                                        .foregroundStyle(.packitTeal)
                                    Text(phase.label)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(procs) { proc in
                                    procedureCard(proc)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var isEditing: Bool { editingProcID != nil }

    private func isEditingProc(_ proc: Procedure) -> Bool {
        editingProcID == proc.id
    }

    private func procedureCard(_ proc: Procedure) -> some View {
        let editing = isEditingProc(proc)
        let sortedSteps = proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder })

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button {
                    store.toggleProcedureCollapse(tripID: trip.id, procedureID: proc.id)
                } label: {
                    HStack {
                        Image(systemName: proc.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 12)
                        Text(proc.name)
                            .font(.callout.weight(.semibold))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(proc.completedCount)/\(proc.steps.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                ProgressView(value: proc.progress)
                    .tint(proc.progress >= 1 ? .packitGreen : .packitTeal)
                    .frame(width: 50)

                // Edit toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if editing {
                            editingProcID = nil
                            addingStepToProcID = nil
                        } else {
                            editingProcID = proc.id
                        }
                    }
                } label: {
                    Image(systemName: editing ? "checkmark.circle.fill" : "pencil")
                        .font(.caption)
                        .foregroundStyle(editing ? .packitGreen : .secondary)
                }
                .buttonStyle(.plain)
                .help(editing ? "Done editing" : "Edit steps")

                // Actions menu
                Menu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            editingProcID = editing ? nil : proc.id
                        }
                    } label: {
                        Label(editing ? "Done Editing" : "Edit Steps", systemImage: "pencil")
                    }
                    Button { store.resetProcedure(tripID: trip.id, procedureID: proc.id) } label: {
                        Label("Reset All Steps", systemImage: "arrow.counterclockwise")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.removeProcedure(from: trip.id, procedureID: proc.id)
                    } label: {
                        Label("Remove Procedure", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.packitTeal.opacity(0.04))

            // Steps
            if !proc.isCollapsed {
                VStack(spacing: 0) {
                    ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                        VStack(spacing: 0) {
                            // Drop indicator line
                            if editing && dropTargetStepID == step.id {
                                Rectangle()
                                    .fill(Color.packitTeal)
                                    .frame(height: 2)
                                    .padding(.horizontal, 12)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                // Edit mode: drag handle + delete
                                if editing {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 18, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption2.monospacedDigit().weight(.medium))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 18, alignment: .trailing)
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        store.toggleProcedureStep(tripID: trip.id, procedureID: proc.id, stepID: step.id)
                                    }
                                } label: {
                                    Image(systemName: step.isComplete ? "checkmark.square.fill" : "square")
                                        .font(.body)
                                        .foregroundStyle(step.isComplete ? .packitGreen : .secondary)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)

                                if editingStepID == step.id {
                                    VStack(alignment: .leading, spacing: 4) {
                                        TextField("Step text", text: $editStepText)
                                            .font(.callout)
                                            .textFieldStyle(.plain)
                                            .onSubmit { saveStepEdit(proc: proc, step: step) }
                                        TextField("Notes (optional)", text: $editStepNotes)
                                            .font(.caption)
                                            .textFieldStyle(.plain)
                                            .foregroundStyle(.secondary)
                                        HStack(spacing: 8) {
                                            Button("Save") { saveStepEdit(proc: proc, step: step) }
                                                .font(.caption2)
                                                .foregroundStyle(.packitTeal)
                                            Button("Cancel") { editingStepID = nil }
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.text)
                                            .font(.callout)
                                            .strikethrough(step.isComplete)
                                            .foregroundStyle(step.isComplete ? .tertiary : .primary)
                                        if let notes = step.notes, !notes.isEmpty {
                                            Text(notes)
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .onTapGesture(count: 2) {
                                        editStepText = step.text
                                        editStepNotes = step.notes ?? ""
                                        editingStepID = step.id
                                    }
                                }

                                Spacer()

                                if editing {
                                    Button(role: .destructive) {
                                        store.removeProcedureStep(tripID: trip.id, procedureID: proc.id, stepID: step.id)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.red.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.03) : .clear)
                            .if(editing) { view in
                                view
                                    .draggable(step.id.uuidString)
                                    .dropDestination(for: String.self) { droppedIDs, _ in
                                        dropTargetStepID = nil
                                        guard let droppedID = droppedIDs.first,
                                              let draggedUUID = UUID(uuidString: droppedID) else { return false }
                                        store.moveProcedureStep(tripID: trip.id, procedureID: proc.id, stepID: draggedUUID, before: step.id)
                                        return true
                                    } isTargeted: { targeted in
                                        dropTargetStepID = targeted ? step.id : (dropTargetStepID == step.id ? nil : dropTargetStepID)
                                    }
                            }
                            .contextMenu {
                                Button {
                                    editStepText = step.text
                                    editStepNotes = step.notes ?? ""
                                    editingStepID = step.id
                                } label: {
                                    Label("Edit Step", systemImage: "pencil")
                                }
                                if editing {
                                    Divider()
                                    Button(role: .destructive) {
                                        store.removeProcedureStep(tripID: trip.id, procedureID: proc.id, stepID: step.id)
                                    } label: {
                                        Label("Remove Step", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    // Inline add step (edit mode only)
                    if editing {
                        if addingStepToProcID == proc.id {
                            HStack(spacing: 8) {
                                // Order field
                                TextField("#", text: $newStepOrder)
                                    .font(.caption.monospacedDigit())
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 32)

                                TextField("New step...", text: $newStepText)
                                    .font(.callout)
                                    .textFieldStyle(.plain)
                                    .onSubmit { commitNewStep(proc) }

                                Button("Add") { commitNewStep(proc) }
                                    .font(.caption)
                                    .disabled(newStepText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.packitTeal.opacity(0.03))
                        } else {
                            Button {
                                addingStepToProcID = proc.id
                                newStepText = ""
                                newStepOrder = "\(proc.steps.count + 1)"
                            } label: {
                                Label("Add Step", systemImage: "plus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.packitTeal)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator.opacity(0.4), lineWidth: 0.5))
    }

    private func saveStepEdit(proc: Procedure, step: ProcedureStep) {
        let trimmed = editStepText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.updateProcedureStep(
            tripID: trip.id,
            procedureID: proc.id,
            stepID: step.id,
            text: trimmed,
            notes: editStepNotes.isEmpty ? nil : editStepNotes
        )
        editingStepID = nil
    }

    private func commitNewStep(_ proc: Procedure) {
        let trimmed = newStepText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let targetPosition = max(1, Int(newStepOrder) ?? (proc.steps.count + 1))
        let insertIndex = min(targetPosition - 1, proc.steps.count)

        store.addProcedureStep(
            tripID: trip.id,
            procedureID: proc.id,
            text: trimmed,
            atPosition: insertIndex
        )

        newStepText = ""
        // Next add defaults to end of list (total steps + 1 after this add)
        if let updatedTrip = store.trips.first(where: { $0.id == trip.id }),
           let pIdx = updatedTrip.procedures.firstIndex(where: { $0.id == proc.id }) {
            newStepOrder = "\(updatedTrip.procedures[pIdx].steps.count + 1)"
        } else {
            newStepOrder = "\(targetPosition + 1)"
        }
    }
}

// MARK: - Conditional modifier

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
