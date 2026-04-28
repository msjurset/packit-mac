import SwiftUI

/// Compact popover for editing a category's icon and color from the trip's
/// item list. Auto-creates the category record if one doesn't exist yet.
struct InlineCategoryIconColorEditor: View {
    @Environment(PackItStore.self) private var store
    let categoryName: String
    var onCommit: (Bool) -> Void

    @State private var icon: String = "square.grid.2x2.fill"
    @State private var color: String = CategoryColor.gray.rawValue

    private var resolvedColor: Color {
        CategoryColor(rawValue: color)?.color ?? .gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                preview
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.headline)
                    Text(icon)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }

            CategoryColorPicker(token: $color)

            Divider()

            CategoryIconGridView(symbol: $icon, color: resolvedColor, gridHeight: 200)

            HStack {
                Spacer()
                Button("Cancel") { onCommit(false) }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    save()
                    onCommit(false)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 380, height: 470)
        .onAppear {
            if let existing = store.category(named: categoryName) {
                icon = existing.icon
                color = existing.color
            } else {
                icon = store.categoryIcon(for: categoryName)
                color = CategoryColor.gray.rawValue
            }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(resolvedColor.opacity(0.18))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .foregroundStyle(resolvedColor)
                .font(.title3)
        }
    }

    private func save() {
        if var existing = store.category(named: categoryName) {
            existing.icon = icon
            existing.color = color
            store.upsertCategory(existing)
        } else {
            let new = ItemCategory(name: categoryName, icon: icon, color: color)
            store.upsertCategory(new)
        }
    }
}
