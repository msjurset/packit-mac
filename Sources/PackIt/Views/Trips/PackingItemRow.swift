import SwiftUI

struct PackingItemRow: View {
    @Environment(PackItStore.self) private var store
    let item: TripItem
    let tripID: UUID
    @State private var isHovered = false

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
                    Text(item.name)
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
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: item.isPacked)
        .contextMenu {
            Button(role: .destructive) {
                store.removeItem(from: tripID, itemID: item.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var itemColor: Color {
        if item.isOverdue && item.priority >= .high {
            return .packitRed
        }
        return .secondary
    }

    private var itemBackground: Color {
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
}
