import SwiftUI

struct PackingItemRow: View {
    @Environment(PackItStore.self) private var store
    let item: TripItem
    let tripID: UUID

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.togglePacked(tripID: tripID, itemID: item.id)
            } label: {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPacked ? .green : itemColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .strikethrough(item.isPacked)
                        .foregroundStyle(item.isPacked ? .secondary : .primary)
                    if item.isAdHoc {
                        Text("new")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.purple.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let due = item.dueDate {
                Text(due.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(item.isOverdue ? .red : .secondary)
            }

            Image(systemName: item.priority.icon)
                .font(.caption)
                .foregroundStyle(priorityColor)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(itemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button("Remove", role: .destructive) {
                store.removeItem(from: tripID, itemID: item.id)
            }
        }
    }

    private var itemColor: Color {
        if item.isOverdue && item.priority >= .high {
            return .red
        }
        return .secondary
    }

    private var itemBackground: Color {
        if item.isPacked {
            return .green.opacity(0.05)
        }
        if item.isOverdue && item.priority >= .high {
            return .red.opacity(0.08)
        }
        return .clear
    }

    private var priorityColor: Color {
        switch item.priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
