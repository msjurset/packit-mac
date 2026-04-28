import SwiftUI
import AppKit

/// NSTextField-backed search field with explicit key callbacks for autocomplete.
/// Tab and Down advance suggestions; Up goes back; Enter submits or accepts.
/// Uses NoAutoFillTextField so the macOS inline-prediction popup is suppressed.
struct TokenizedSearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var isFocused: Binding<Bool>?
    var autoFocus: Bool = false
    /// Increment to programmatically re-focus the field (e.g. after a click
    /// on a suggestion row that briefly stole first-responder).
    var refocusToken: Int = 0
    var onAdvance: (Bool) -> Void = { _ in }   // true = forward, false = backward
    var onSubmit: () -> Void = {}
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused, onAdvance: onAdvance, onSubmit: onSubmit, onCancel: onCancel)
    }

    func makeNSView(context: Context) -> NSTextField {
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
        if autoFocus {
            DispatchQueue.main.async {
                if let window = tf.window {
                    window.makeFirstResponder(tf)
                }
            }
        }
        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        if tf.stringValue != text {
            tf.stringValue = text
            // After a programmatic update, NSTextField's field editor defaults to
            // selecting all text. Force the cursor to the end instead so the user
            // can keep typing without clicking to deselect.
            if let editor = tf.currentEditor() {
                let end = (tf.stringValue as NSString).length
                editor.selectedRange = NSRange(location: end, length: 0)
            }
        }
        if context.coordinator.lastRefocusToken != refocusToken {
            context.coordinator.lastRefocusToken = refocusToken
            DispatchQueue.main.async {
                if let window = tf.window, window.firstResponder !== tf {
                    window.makeFirstResponder(tf)
                    if let editor = tf.currentEditor() {
                        let end = (tf.stringValue as NSString).length
                        editor.selectedRange = NSRange(location: end, length: 0)
                    }
                }
            }
        }
        context.coordinator.onAdvance = onAdvance
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onCancel = onCancel
        context.coordinator.isFocused = isFocused
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var isFocused: Binding<Bool>?
        var onAdvance: (Bool) -> Void
        var onSubmit: () -> Void
        var onCancel: () -> Void
        var lastRefocusToken: Int = 0

        init(text: Binding<String>, isFocused: Binding<Bool>?, onAdvance: @escaping (Bool) -> Void, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.text = text
            self.isFocused = isFocused
            self.onAdvance = onAdvance
            self.onSubmit = onSubmit
            self.onCancel = onCancel
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            text.wrappedValue = tf.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isFocused?.wrappedValue = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isFocused?.wrappedValue = false
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertTab(_:)),
                 #selector(NSResponder.moveDown(_:)):
                onAdvance(true)
                return true
            case #selector(NSResponder.insertBacktab(_:)),
                 #selector(NSResponder.moveUp(_:)):
                onAdvance(false)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                onCancel()
                return true
            default:
                return false
            }
        }
    }
}
