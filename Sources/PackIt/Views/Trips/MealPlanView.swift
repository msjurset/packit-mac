import SwiftUI
import PackItKit

struct MealPlanView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var editingCell: EditingCell?
    @State private var editText = ""
    @State private var editingPrepNotes = false
    @State private var prepNotesText = ""

    struct EditingCell: Equatable {
        let dayID: UUID
        let mealType: MealType
    }

    var body: some View {
        if let plan = trip.mealPlan {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Prep notes
                    prepNotesSection(plan: plan)

                    // Day × Meal grid
                    mealGrid(plan: plan)

                }
                .padding()
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("No meal plan yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Create a meal plan to organize breakfast, lunch, dinner, snacks, and beverages for each day of your trip.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                Button("Create Meal Plan") {
                    store.initMealPlan(tripID: trip.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(.packitTeal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Prep Notes

    private func prepNotesSection(plan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Food Prep", systemImage: "list.clipboard")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if editingPrepNotes {
                    Button("Done") {
                        store.updateMealPrepNotes(tripID: trip.id, notes: prepNotesText)
                        editingPrepNotes = false
                    }
                    .font(.caption)
                    .foregroundStyle(.packitTeal)
                } else {
                    Button("Edit") {
                        prepNotesText = plan.prepNotes
                        editingPrepNotes = true
                    }
                    .font(.caption)
                    .foregroundStyle(.packitTeal)
                }
            }

            if editingPrepNotes {
                TextEditor(text: $prepNotesText)
                    .font(.callout)
                    .frame(minHeight: 50, maxHeight: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 0.5))
            } else if !plan.prepNotes.isEmpty {
                Text(plan.prepNotes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        prepNotesText = plan.prepNotes
                        editingPrepNotes = true
                    }
            } else {
                Text("Add food prep notes: boil eggs, chop veg, freeze meats...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .onTapGesture {
                        prepNotesText = ""
                        editingPrepNotes = true
                    }
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Meal Grid

    private func mealGrid(plan: MealPlan) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 70)

                ForEach(MealType.allCases) { type in
                    HStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(.packitTeal.opacity(0.7))
                        Text(type.label)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.packitTeal.opacity(0.06))

            Divider()

            // Day rows
            ForEach(Array(plan.days.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        // Day label
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.dayLabel)
                                .font(.system(size: 12, weight: .bold))
                            Text(day.dateLabel)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 70, alignment: .leading)
                        .padding(.vertical, 8)

                        // Meal cells with subtle vertical separators
                        ForEach(MealType.allCases) { type in
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(.separator.opacity(0.3))
                                    .frame(width: 0.5)
                                mealCell(day: day, type: type)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .background(index.isMultiple(of: 2) ? Color.secondary.opacity(0.04) : .clear)

                    if index < plan.days.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
        .background(.secondary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator.opacity(0.5), lineWidth: 0.5))
    }

    // MARK: - Meal Cell

    private func mealCell(day: MealDay, type: MealType) -> some View {
        let slot = day.slot(for: type)
        let isEditing = editingCell == EditingCell(dayID: day.id, mealType: type)

        return Group {
            if isEditing {
                VStack(spacing: 2) {
                    TextField("Items (comma separated)", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .onSubmit { commitEdit(dayID: day.id, type: type) }
                        .onExitCommand { editingCell = nil }
                    HStack {
                        Button("Save") { commitEdit(dayID: day.id, type: type) }
                            .font(.caption2)
                            .foregroundStyle(.packitTeal)
                        Button("Cancel") { editingCell = nil }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding(4)
            } else {
                Text(slot.isEmpty ? "—" : slot.display)
                    .font(.caption)
                    .foregroundStyle(slot.isEmpty ? .tertiary : .primary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editText = slot.items.joined(separator: ", ")
                        editingCell = EditingCell(dayID: day.id, mealType: type)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func commitEdit(dayID: UUID, type: MealType) {
        let items = editText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        store.updateMealSlot(tripID: trip.id, dayID: dayID, mealType: type, items: items)
        editingCell = nil
    }

}
