import SwiftUI
import PackItKit

struct CategoriesSettingsView: View {
    @Environment(PackItStore.self) private var store
    @State private var editing: ItemCategory?
    @State private var addingNew = false

    private var sortedCategories: [ItemCategory] {
        store.categories.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Categories")
                    .font(.headline)
                Spacer()
                Button {
                    addingNew = true
                } label: {
                    Label("New", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Text("Customize how categories appear on your packing items.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedCategories) { cat in
                        row(cat)
                            .onTapGesture(count: 2) { editing = cat }
                    }
                    if sortedCategories.isEmpty {
                        Text("No categories yet — add one with the New button above, or create them by typing into the Category field on any item.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(20)
                    }
                }
            }
        }
        .sheet(item: $editing) { cat in
            CategoryEditorSheet(category: cat, isNew: false)
        }
        .sheet(isPresented: $addingNew) {
            CategoryEditorSheet(
                category: ItemCategory(name: "", icon: "square.grid.2x2.fill", color: CategoryColor.gray.rawValue),
                isNew: true
            )
        }
    }

    @ViewBuilder
    private func row(_ cat: ItemCategory) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill((CategoryColor(rawValue: cat.color)?.color ?? .gray).opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: cat.icon)
                    .foregroundStyle(CategoryColor(rawValue: cat.color)?.color ?? .gray)
                    .font(.callout)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(cat.name)
                    .font(.callout)
                Text("\(usageCount(cat)) item\(usageCount(cat) == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button { editing = cat } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Edit")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(Color.primary.opacity(0.001))
    }

    private func usageCount(_ cat: ItemCategory) -> Int {
        var n = 0
        let lower = cat.name.lowercased()
        for t in store.templates { n += t.items.filter { $0.category?.lowercased() == lower }.count }
        for t in store.trips { n += t.items.filter { $0.category?.lowercased() == lower }.count }
        return n
    }
}

// MARK: - Editor sheet

struct CategoryEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var showDeleteConfirm = false
    let originalID: UUID
    let isNew: Bool
    let originalName: String

    init(category: ItemCategory, isNew: Bool) {
        self._name = State(initialValue: category.name)
        self._icon = State(initialValue: category.icon)
        self._color = State(initialValue: category.color)
        self.originalID = category.id
        self.isNew = isNew
        self.originalName = category.name
    }

    private var resolvedColor: Color {
        CategoryColor(rawValue: color)?.color ?? .gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isNew ? "New Category" : "Edit Category")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                preview
                LeadingTextField(label: "Name", text: $name, prompt: "e.g. Toiletries")
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                CategoryColorPicker(token: $color)
            }

            Divider()

            CategoryIconGridView(symbol: $icon, color: resolvedColor, gridHeight: 240)

            HStack {
                if !isNew {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440, height: 540)
        .alert("Delete \"\(originalName)\"?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteCategory(id: originalID)
                dismiss()
            }
        } message: {
            Text("Items with this category will keep the name but lose the custom icon and color.")
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(resolvedColor.opacity(0.18))
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .foregroundStyle(resolvedColor)
                .font(.title3)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // If the name changed (existing category being renamed), do a global rename
        // so all items currently using the old name get updated.
        if !isNew && trimmed.lowercased() != originalName.lowercased() {
            store.renameCategoryGlobally(from: originalName, to: trimmed)
        }

        let updated = ItemCategory(id: originalID, name: trimmed, icon: icon, color: color)
        store.upsertCategory(updated)
        dismiss()
    }
}
