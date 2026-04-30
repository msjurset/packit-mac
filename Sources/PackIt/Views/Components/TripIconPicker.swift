import SwiftUI
import PackItKit
import AppKit

struct TripIconPicker: View {
    @Binding var selection: TripIcon
    @State private var showPicker = false
    @State private var query = ""
    @State private var keyMonitor: Any?

    private let columnCount = 7
    private let columns: [GridItem] = Array(repeating: GridItem(.fixed(56), spacing: 6), count: 7)

    private var filteredIcons: [TripIcon] {
        TripIcon.allCases.filter { $0.matches(query: query) }
    }

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            TripIconView(icon: selection, size: 36)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help("Choose trip icon")
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            popoverContent
                .onAppear {
                    query = ""
                    installKeyMonitor()
                }
                .onDisappear { removeKeyMonitor() }
        }
    }

    @ViewBuilder
    private var popoverContent: some View {
        VStack(spacing: 10) {
            searchField
            if filteredIcons.isEmpty {
                emptyState
            } else {
                gridContent
            }
        }
        .padding(14)
        .frame(width: 460)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            IconPickerSearchField(
                text: $query,
                placeholder: "Search icons…",
                onYieldFocus: { /* NSEvent monitor takes over */ },
                onSubmit: { showPicker = false }
            )
            .frame(height: 20)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
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
    }

    private var gridContent: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(filteredIcons) { icon in
                iconTile(icon)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No icons match \"\(query)\"")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func iconTile(_ icon: TripIcon) -> some View {
        let isSelected = (selection == icon)
        Button {
            selection = icon
            showPicker = false
        } label: {
            VStack(spacing: 3) {
                TripIconView(icon: icon, size: 32)
                Text(icon.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 22, alignment: .top)
            }
            .frame(width: 56, height: 64)
            .background(isSelected ? icon.color.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(isSelected ? icon.color.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(icon.label)
    }

    // MARK: - Key handling

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKey(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }

    /// Returns true if the event was consumed (so the caller returns nil).
    private func handleKey(_ event: NSEvent) -> Bool {
        // If the search field currently has focus, let NSTextField handle keys —
        // Tab/↓/Enter are already intercepted inside IconPickerSearchField's delegate.
        if event.window?.firstResponder is NSTextView { return false }

        if event.modifierFlags.intersection([.command, .control, .option]).isEmpty == false {
            return false
        }

        switch event.keyCode {
        case 123: moveSelection(dx: -1, dy: 0); return true   // ←
        case 124: moveSelection(dx: 1, dy: 0); return true    // →
        case 125: moveSelection(dx: 0, dy: 1); return true    // ↓
        case 126: moveSelection(dx: 0, dy: -1); return true   // ↑
        case 36, 76:                                          // Return / Enter
            showPicker = false
            return true
        default:
            break
        }

        if let chars = event.charactersIgnoringModifiers?.lowercased() {
            switch chars {
            case "h": moveSelection(dx: -1, dy: 0); return true
            case "l": moveSelection(dx: 1, dy: 0); return true
            case "k": moveSelection(dx: 0, dy: -1); return true
            case "j": moveSelection(dx: 0, dy: 1); return true
            default: break
            }
        }
        return false
    }

    private func moveSelection(dx: Int, dy: Int) {
        let icons = filteredIcons
        guard !icons.isEmpty else { return }
        let currentIdx = icons.firstIndex(of: selection) ?? -1
        if currentIdx < 0 {
            selection = icons[0]
            return
        }
        let row = currentIdx / columnCount
        let col = currentIdx % columnCount
        let lastRow = (icons.count - 1) / columnCount
        let newCol = max(0, min(columnCount - 1, col + dx))
        let newRow = max(0, min(lastRow, row + dy))
        var newIdx = newRow * columnCount + newCol
        if newIdx >= icons.count { newIdx = icons.count - 1 }
        selection = icons[newIdx]
    }
}

// MARK: - AppKit-backed search field

/// A plain `NSTextField` wrapper that routes Tab / ↓ / Enter to callbacks
/// and yields first responder so the picker's key monitor takes over.
struct IconPickerSearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onYieldFocus: () -> Void
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onYieldFocus: onYieldFocus, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSTextField {
        // Use NoAutoFillTextField to suppress the macOS autofill / inline-prediction
        // popup that otherwise covers content rendered below this field.
        let tf = NoAutoFillTextField()
        tf.placeholderString = placeholder
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.font = NSFont.systemFont(ofSize: 13)
        tf.cell?.usesSingleLineMode = true
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        if tf.stringValue != text {
            tf.stringValue = text
        }
        context.coordinator.onYieldFocus = onYieldFocus
        context.coordinator.onSubmit = onSubmit
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var onYieldFocus: () -> Void
        var onSubmit: () -> Void

        init(text: Binding<String>, onYieldFocus: @escaping () -> Void, onSubmit: @escaping () -> Void) {
            self.text = text
            self.onYieldFocus = onYieldFocus
            self.onSubmit = onSubmit
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            text.wrappedValue = tf.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertTab(_:)),
                 #selector(NSResponder.moveDown(_:)):
                control.window?.makeFirstResponder(nil)
                onYieldFocus()
                return true
            case #selector(NSResponder.insertNewline(_:)):
                onSubmit()
                return true
            default:
                return false
            }
        }
    }
}
