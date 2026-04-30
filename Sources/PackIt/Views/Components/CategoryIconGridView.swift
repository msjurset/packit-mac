import SwiftUI
import PackItKit
import AppKit

/// Inline icon grid for picking an SF Symbol from `CategoryIconLibrary`.
/// Embed inside any sheet or popover; no nested popover needed.
struct CategoryIconGridView: View {
    @Binding var symbol: String
    var color: Color = .secondary
    var gridHeight: CGFloat = 220

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private let columns: [GridItem] = Array(repeating: GridItem(.fixed(46), spacing: 4), count: 6)

    private var filtered: [CategoryIconLibrary.Entry] {
        CategoryIconLibrary.search(query)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                IconPickerSearchField(
                    text: $query,
                    placeholder: "Search icons…",
                    onYieldFocus: { searchFocused = false },
                    onSubmit: { searchFocused = false }
                )
                .frame(height: 18)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 5))

            if filtered.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No icons match \"\(query)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(filtered) { entry in
                            tile(entry)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(height: gridHeight)
            }
        }
    }

    @ViewBuilder
    private func tile(_ entry: CategoryIconLibrary.Entry) -> some View {
        let isSelected = symbol == entry.symbol
        Button {
            symbol = entry.symbol
        } label: {
            VStack(spacing: 1) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(height: 20)
                Text(entry.label)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 18, alignment: .top)
            }
            .frame(width: 46, height: 50)
            .background(isSelected ? color.opacity(0.18) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isSelected ? color.opacity(0.55) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(entry.label)
    }
}
