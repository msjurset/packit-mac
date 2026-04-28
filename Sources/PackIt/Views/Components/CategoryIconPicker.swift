import SwiftUI
import AppKit

/// Popover button that lets the user pick an SF Symbol from `CategoryIconLibrary`.
/// Mirrors the `TripIconPicker` UX: searchable grid, plain-click selection.
struct CategoryIconPicker: View {
    @Binding var symbol: String
    var color: Color = .secondary
    @State private var isOpen = false
    @State private var query = ""
    @State private var keyMonitor: Any?

    private let columnCount = 7
    private let columns: [GridItem] = Array(repeating: GridItem(.fixed(56), spacing: 6), count: 7)

    private var filtered: [CategoryIconLibrary.Entry] {
        CategoryIconLibrary.search(query)
    }

    var body: some View {
        Button { isOpen.toggle() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: symbol.isEmpty ? "square.grid.2x2.fill" : symbol)
                    .font(.title3)
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help("Pick an icon")
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            popoverContent
                .onAppear {
                    query = ""
                    installMonitor()
                }
                .onDisappear { removeMonitor() }
        }
    }

    @ViewBuilder
    private var popoverContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                IconPickerSearchField(
                    text: $query,
                    placeholder: "Search icons…",
                    onYieldFocus: {},
                    onSubmit: { isOpen = false }
                )
                .frame(height: 20)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if filtered.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No icons match \"\(query)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(filtered) { entry in
                            tile(for: entry)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
        .padding(14)
        .frame(width: 460)
    }

    @ViewBuilder
    private func tile(_ entry: CategoryIconLibrary.Entry) -> some View {
        Button {
            symbol = entry.symbol
            isOpen = false
        } label: {
            VStack(spacing: 3) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(height: 22)
                Text(entry.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 22, alignment: .top)
            }
            .frame(width: 56, height: 60)
            .background(symbol == entry.symbol ? color.opacity(0.18) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(symbol == entry.symbol ? color.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(entry.label)
    }

    @ViewBuilder
    private func tile(for entry: CategoryIconLibrary.Entry) -> some View {
        tile(entry)
    }

    private func installMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {  // Esc
                isOpen = false
                return nil
            }
            return event
        }
    }

    private func removeMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

/// Compact horizontal palette for picking a `CategoryColor`.
struct CategoryColorPicker: View {
    @Binding var token: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CategoryColor.allCases, id: \.self) { c in
                Button {
                    token = c.rawValue
                } label: {
                    ZStack {
                        Circle()
                            .fill(c.color)
                            .frame(width: 22, height: 22)
                        if token == c.rawValue {
                            Circle()
                                .strokeBorder(Color.primary, lineWidth: 2)
                                .frame(width: 26, height: 26)
                        }
                    }
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(c.label)
            }
        }
    }
}
