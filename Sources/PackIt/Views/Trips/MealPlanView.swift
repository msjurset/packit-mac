import SwiftUI
import PackItKit

struct MealPlanView: View {
    @Environment(PackItStore.self) private var store
    let trip: TripInstance
    @State private var editingCell: EditingCell?
    @FocusState private var focusedCell: EditingCell?
    @State private var editText = ""
    @State private var editIcons: [String] = []
    @State private var showIconPicker = false
    @State private var editingPrepNotes = false
    @FocusState private var focusedPrepNotes: Bool
    @State private var prepNotesText = ""

    struct EditingCell: Hashable, Equatable {
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
            .onChange(of: focusedCell) { old, new in
                if let old = old, new == nil {
                    // Delay the commit slightly. If showIconPicker becomes true during this time
                    // (from a button click), we don't close the cell.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showIconPicker {
                            commitEdit(dayID: old.dayID, type: old.mealType)
                        }
                    }
                }
            }
            .onChange(of: showIconPicker) { old, new in
                // When the icon picker closes, if no cell is focused, 
                // it means the user clicked away entirely. Commit now.
                if old && !new && focusedCell == nil {
                    if let editing = editingCell {
                        commitEdit(dayID: editing.dayID, type: editing.mealType)
                    }
                }
            }
            .onChange(of: focusedPrepNotes) { old, new in
                if old && !new {
                    if plan.prepNotes != prepNotesText {
                        store.updateMealPrepNotes(tripID: trip.id, notes: prepNotesText)
                    }
                    editingPrepNotes = false
                }
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
            }

            if editingPrepNotes {
                TextEditor(text: $prepNotesText)
                    .font(.callout)
                    .frame(minHeight: 50, maxHeight: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 0.5))
                    .focused($focusedPrepNotes)
                    .onAppear {
                        focusedPrepNotes = true
                    }
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
                        FoodIcon(symbol: type.icon, size: 10, color: .packitTeal.opacity(0.7))
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
        let cellID = EditingCell(dayID: day.id, mealType: type)
        let isEditing = editingCell == cellID

        return Group {
            if isEditing {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Items (comma separated)", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .focused($focusedCell, equals: cellID)
                        .onSubmit { commitEdit(dayID: day.id, type: type) }
                        .onExitCommand { 
                            editingCell = nil 
                            focusedCell = nil
                        }
                    
                    HStack(spacing: 4) {
                        ForEach(editIcons, id: \.self) { symbol in
                            FoodIcon(symbol: symbol, size: 12)
                                .padding(2)
                                .background(.packitTeal.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .onTapGesture {
                                    editIcons.removeAll { $0 == symbol }
                                }
                        }
                        
                        Button {
                            showIconPicker = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                            FoodIconPicker(selectedIcons: $editIcons)
                        }
                    }
                }
                .padding(4)
                .background(Color.packitTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onAppear {
                    focusedCell = cellID
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if !slot.icons.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(slot.icons, id: \.self) { symbol in
                                FoodIcon(symbol: symbol, size: 12, color: .packitTeal.opacity(0.8))
                            }
                        }
                    }
                    
                    if slot.isEmpty {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else if !slot.items.isEmpty {
                        MarkdownPreview(source: slot.display, style: .compact)
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    editText = slot.items.joined(separator: ", ")
                    editIcons = slot.icons
                    editingCell = cellID
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func commitEdit(dayID: UUID, type: MealType) {
        let items = editText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        // Only update if the content actually changed to avoid unnecessary undo steps
        let currentSlot = trip.mealPlan?.days.first(where: { $0.id == dayID })?.slot(for: type)
        if currentSlot?.items != items || currentSlot?.icons != editIcons {
            store.updateMealSlot(tripID: trip.id, dayID: dayID, mealType: type, items: items, icons: editIcons)
        }
        
        // Only clear editing state if we aren't currently showing the icon picker
        if !showIconPicker {
            editingCell = nil
            focusedCell = nil
        }
    }

}

// MARK: - Food Icon Picker

struct FoodIconPicker: View {
    @Binding var selectedIcons: [String]
    @State private var searchText = ""
    
    private let columns = [GridItem(.adaptive(minimum: 32), spacing: 8)]
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search food, cuisine, etc...", text: $searchText)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
            
            Divider()
            
            ScrollView {
                let matches = FoodIconLibrary.search(searchText)
                if matches.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("No icons found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(matches) { entry in
                            let isSelected = selectedIcons.contains(entry.symbol)
                            Button {
                                if isSelected {
                                    selectedIcons.removeAll { $0 == entry.symbol }
                                } else {
                                    selectedIcons.append(entry.symbol)
                                }
                            } label: {
                                FoodIcon(symbol: entry.symbol, size: 18, color: isSelected ? .packitTeal : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(isSelected ? Color.packitTeal.opacity(0.15) : Color.primary.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(isSelected ? Color.packitTeal.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(entry.label)
                        }
                    }
                    .padding(12)
                }
            }
            .frame(height: 300)
        }
        .frame(width: 240)
    }
}
