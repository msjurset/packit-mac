import SwiftUI
import PackItKit
import AppKit

struct PackingItemRow: View {
    @Environment(PackItStore.self) private var store
    let item: TripItem
    let tripID: UUID
    var showOwnerSuffix: Bool = false
    var isSelected: Bool = false
    var selectionCount: Int = 0
    var isSearchMatch: Bool = false
    var isCurrentSearchMatch: Bool = false
    var onEdit: () -> Void = {}
    var onSelect: (EventModifiers) -> Void = { _ in }
    var onBulkSetOwner: (String?) -> Void = { _ in }
    var onBulkDuplicate: (String?) -> Void = { _ in }
    var onBulkRemove: () -> Void = {}
    @State private var isHovered = false

    private var trip: TripInstance? {
        store.trips.first { $0.id == tripID }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    store.togglePacked(tripID: tripID, itemID: item.id)
                }
            } label: {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(item.isPacked ? .packitGreen : itemColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isPacked ? "Unpack \(item.name)" : "Pack \(item.name)")

            Image(systemName: item.priority.icon)
                .font(.caption2)
                .foregroundStyle(Color.priorityColor(item.priority))
                .offset(y: -1)
                .accessibilityLabel("\(item.priority.label) priority")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .strikethrough(item.isPacked)
                        .foregroundStyle(item.isPacked ? .secondary : .primary)
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.caption2.bold().monospacedDigit())
                            .foregroundStyle(item.isPacked ? Color.secondary : Color.packitTeal)
                    }
                    if item.isAdHoc {
                        Text("new")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.purple.opacity(0.12))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                    if let due = item.dueDate {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(item.isOverdue ? .packitRed : .secondary)
                    }
                }
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(itemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: item.isPacked)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { onEdit() }
        )
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                let mods = NSEvent.modifierFlags
                if mods.contains(.command) {
                    onSelect(.command)
                } else if mods.contains(.shift) {
                    onSelect(.shift)
                } else {
                    onSelect([])
                }
            }
        )
        .contextMenu {
            let actsOnSelection = isSelected && selectionCount > 1
            let scopeSuffix = actsOnSelection ? " (\(selectionCount) items)" : ""

            Button {
                onEdit()
            } label: {
                Label("Edit…", systemImage: "pencil")
            }
            if let trip, !actsOnSelection {
                let categories = tripCategories(trip)
                if !categories.isEmpty {
                    Menu {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                store.moveTripItem(in: tripID, itemID: item.id, toCategory: cat == "Uncategorized" ? nil : cat)
                            } label: {
                                Label(cat, systemImage: (item.category ?? "Uncategorized") == cat ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Move to Category", systemImage: "folder")
                    }
                }
            }
            if let trip, !trip.members.isEmpty {
                Menu {
                    Button {
                        if actsOnSelection { onBulkSetOwner(nil) } else { reassignOwner(nil) }
                    } label: {
                        Label("Shared (everyone)", systemImage: !actsOnSelection && item.owner == nil ? "checkmark" : "")
                    }
                    ForEach(trip.members, id: \.self) { m in
                        Button {
                            if actsOnSelection { onBulkSetOwner(m) } else { reassignOwner(m) }
                        } label: {
                            Label(m, systemImage: !actsOnSelection && item.owner == m ? "checkmark" : "")
                        }
                    }
                } label: {
                    Label("Owner\(scopeSuffix)", systemImage: "person.crop.circle")
                }
                Menu {
                    Button("Shared") {
                        if actsOnSelection { onBulkDuplicate(nil) } else { store.duplicateTripItem(in: tripID, itemID: item.id, newOwner: nil) }
                    }
                    ForEach(trip.members, id: \.self) { m in
                        Button(m) {
                            if actsOnSelection { onBulkDuplicate(m) } else { store.duplicateTripItem(in: tripID, itemID: item.id, newOwner: m) }
                        }
                    }
                } label: {
                    Label("Duplicate For\(scopeSuffix)…", systemImage: "plus.square.on.square")
                }
            }
            Divider()
            Button(role: .destructive) {
                if actsOnSelection { onBulkRemove() } else { store.removeItem(from: tripID, itemID: item.id) }
            } label: {
                Label("Remove\(scopeSuffix)", systemImage: "trash")
            }
        }
    }

    private func reassignOwner(_ newOwner: String?) {
        var updated = item
        updated.owner = newOwner
        store.updateTripItem(in: tripID, item: updated)
    }

    private func tripCategories(_ trip: TripInstance) -> [String] {
        let unique = Set(trip.items.map { $0.category ?? "Uncategorized" })
        return unique.sorted()
    }

    private var displayName: String {
        if showOwnerSuffix, let owner = item.owner, !owner.isEmpty {
            return "\(item.name) (\(owner))"
        }
        return item.name
    }

    private var itemColor: Color {
        if item.isOverdue && item.priority >= .high {
            return .packitRed
        }
        return .secondary
    }

    private var itemBackground: Color {
        if isCurrentSearchMatch {
            return .yellow.opacity(0.30)
        }
        if isSearchMatch {
            return .yellow.opacity(0.12)
        }
        if isSelected {
            return .packitTeal.opacity(0.18)
        }
        if item.isPacked {
            return .packitGreen.opacity(0.06)
        }
        if item.isOverdue && item.priority >= .high {
            return .packitRed.opacity(0.06)
        }
        if isHovered {
            return .primary.opacity(0.03)
        }
        return .clear
    }

    private var borderColor: Color {
        if isCurrentSearchMatch { return .yellow }
        if isSelected { return .packitTeal }
        return .clear
    }

    private var borderWidth: CGFloat {
        if isCurrentSearchMatch { return 2 }
        if isSelected { return 2 }
        return 0
    }
}
