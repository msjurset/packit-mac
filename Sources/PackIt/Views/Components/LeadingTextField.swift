import SwiftUI
import AppKit

/// A text field that always left-aligns its text, bypassing macOS Form's forced right-alignment.
/// Uses a subclassed NSTextField (`NoAutoFillTextField`) to suppress the macOS autofill/autocomplete popup.
struct LeadingTextField: NSViewRepresentable {
    let label: String
    @Binding var text: String
    var prompt: String = ""
    var isFocused: Binding<Bool>?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused)
    }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NoAutoFillTextField()
        tf.alignment = .left
        tf.isBordered = true
        tf.isBezeled = true
        tf.bezelStyle = .roundedBezel
        tf.drawsBackground = true
        tf.font = .systemFont(ofSize: NSFont.systemFontSize)
        tf.placeholderString = prompt.isEmpty ? label : prompt
        tf.delegate = context.coordinator
        tf.lineBreakMode = .byTruncatingTail
        tf.cell?.truncatesLastVisibleLine = true
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        if tf.stringValue != text {
            tf.stringValue = text
        }
        tf.alignment = .left
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var isFocused: Binding<Bool>?

        init(text: Binding<String>, isFocused: Binding<Bool>?) {
            self.text = text
            self.isFocused = isFocused
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
    }
}

/// NSTextField that disables every macOS auto-* text feature at three different lifecycle points,
/// which is necessary to reliably suppress the macOS autofill / autocomplete popup.
final class NoAutoFillTextField: NSTextField {
    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { disableAutoFeatures() }
        return ok
    }

    override func textDidBeginEditing(_ notification: Notification) {
        super.textDidBeginEditing(notification)
        disableAutoFeatures()
    }

    override func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        disableAutoFeatures()
        return super.textShouldBeginEditing(textObject)
    }

    private func disableAutoFeatures() {
        guard let editor = currentEditor() as? NSTextView else { return }
        editor.isAutomaticTextCompletionEnabled = false
        editor.isAutomaticSpellingCorrectionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        editor.isContinuousSpellCheckingEnabled = false
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticDataDetectionEnabled = false
        editor.isAutomaticLinkDetectionEnabled = false
        // macOS 14+ added an inline-prediction bar that renders as a
        // large ghost popup beneath the field on focus. The auto-* flags
        // above don't suppress it; this trait does.
        if #available(macOS 14.0, *) {
            editor.inlinePredictionType = .no
        }
    }
}
