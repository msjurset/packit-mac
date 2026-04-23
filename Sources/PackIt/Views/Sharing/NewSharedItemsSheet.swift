import SwiftUI

struct NewSharedItemsSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !store.newSharedItems.isEmpty {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.newSharedItems) { item in
                            row(for: item)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }

            HStack {
                Spacer()
                Button("Got it") {
                    store.acknowledgeNewShared()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.packitTeal)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 380, idealWidth: 440, maxWidth: 520)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.largeTitle)
                .foregroundStyle(.packitTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.title3.bold())
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var titleText: String {
        let items = store.newSharedItems
        if items.count == 1, let first = items.first {
            return "New from \(first.author)"
        }
        let authors = Set(items.map(\.author))
        if authors.count == 1, let only = authors.first {
            return "\(items.count) new items from \(only)"
        }
        return "\(items.count) new shared items"
    }

    private var subtitleText: String {
        let authors = Set(store.newSharedItems.map(\.author))
        if authors.count <= 1 { return "Shared with you through your shared folder." }
        let sorted = authors.sorted().joined(separator: ", ")
        return "Shared by \(sorted)."
    }

    @ViewBuilder
    private func row(for item: NewSharedItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind == .template ? "doc.text" : "suitcase")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                Text(rowSubtitle(for: item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func rowSubtitle(for item: NewSharedItem) -> String {
        let kindLabel = item.kind == .template ? "Template" : "Trip"
        return "\(kindLabel) · Shared by \(item.author)"
    }
}
