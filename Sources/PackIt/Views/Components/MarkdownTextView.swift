import SwiftUI
import AppKit

/// NSTextView-backed markdown editor with smart Enter handling for
/// ordered/unordered/task lists and block quotes. Pressing Enter at the
/// end of a list item continues the list; pressing Enter on an empty
/// list item strips the prefix and exits the list.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.usesFontPanel = false
        textView.usesFindBar = true
        textView.drawsBackground = false
        textView.string = text
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            let clampedLocation = min(selected.location, (text as NSString).length)
            textView.setSelectedRange(NSRange(location: clampedLocation, length: 0))
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewline(in: textView)
            }
            return false
        }

        private func handleNewline(in textView: NSTextView) -> Bool {
            let nsString = textView.string as NSString
            let selection = textView.selectedRange()
            // Only smart-continue for a single insertion point (no selection).
            guard selection.length == 0 else { return false }

            let lineRange = nsString.lineRange(for: NSRange(location: selection.location, length: 0))
            let line = nsString.substring(with: lineRange)
            let lineNoNewline = line.hasSuffix("\n") ? String(line.dropLast()) : line

            let indent = String(lineNoNewline.prefix(while: { $0 == " " || $0 == "\t" }))
            let bodyAfterIndent = String(lineNoNewline.dropFirst(indent.count))

            guard let kind = ListPrefix.detect(in: bodyAfterIndent) else { return false }

            // Smart-continue fires when the caret is at or past the end of the
            // prefix on this line — including mid-line splits. Caret inside
            // the indent/prefix region falls through to the default newline.
            let prefixEnd = lineRange.location + (indent as NSString).length + kind.prefixLength
            guard selection.location >= prefixEnd else { return false }

            let trailing = String(bodyAfterIndent.dropFirst(kind.prefixLength))

            if trailing.isEmpty {
                // Empty list item — strip the indent + prefix to exit the list.
                let suffix = line.hasSuffix("\n") ? "\n" : ""
                let replacement = suffix
                let replaceRange = lineRange
                guard textView.shouldChangeText(in: replaceRange, replacementString: replacement) else {
                    return false
                }
                textView.textStorage?.replaceCharacters(in: replaceRange, with: replacement)
                textView.didChangeText()
                let newCaret = lineRange.location + (replacement as NSString).length
                textView.setSelectedRange(NSRange(location: newCaret, length: 0))
                return true
            }

            let insertion = "\n" + kind.continuation(indent: indent)
            let insertRange = NSRange(location: selection.location, length: 0)
            guard textView.shouldChangeText(in: insertRange, replacementString: insertion) else {
                return false
            }
            textView.textStorage?.replaceCharacters(in: insertRange, with: insertion)
            textView.didChangeText()
            let newCaret = selection.location + (insertion as NSString).length
            textView.setSelectedRange(NSRange(location: newCaret, length: 0))
            return true
        }
    }
}

/// List-prefix kinds the editor recognizes for smart continuation.
enum ListPrefix {
    case unordered(marker: Character)               // "-", "*", "+"
    case task(marker: Character, checked: Bool)     // "- [ ]" or "- [x]"
    case ordered(number: Int)                       // "1.", "23."
    case blockquote                                 // ">"

    /// Length of the prefix on the source line, after any leading indent.
    /// Always includes the single trailing space that follows the marker.
    var prefixLength: Int {
        switch self {
        case .unordered: return 2                   // "- "
        case .task: return 6                        // "- [ ] "
        case .ordered(let n): return String(n).count + 2 // "1. " / "23. "
        case .blockquote: return 2                  // "> "
        }
    }

    /// Prefix to write on the new line when continuing the list.
    func continuation(indent: String) -> String {
        switch self {
        case .unordered(let marker): return indent + "\(marker) "
        case .task(let marker, _): return indent + "\(marker) [ ] "
        case .ordered(let n): return indent + "\(n + 1). "
        case .blockquote: return indent + "> "
        }
    }

    static func detect(in body: String) -> ListPrefix? {
        let chars = Array(body)
        // Task list: "<marker> [<x or space>] " (6 chars min: "- [ ] ").
        if chars.count >= 6,
           let marker = chars.first,
           "-*+".contains(marker),
           chars[1] == " ",
           chars[2] == "[",
           ("xX ".contains(chars[3])),
           chars[4] == "]",
           chars[5] == " " {
            return .task(marker: marker, checked: chars[3].lowercased() == "x")
        }
        // Unordered: "<marker> "
        if chars.count >= 2, let marker = chars.first, "-*+".contains(marker), chars[1] == " " {
            return .unordered(marker: marker)
        }
        // Ordered: "<digits>. "
        var digits = ""
        var i = 0
        while i < chars.count, chars[i].isASCII, chars[i].isNumber {
            digits.append(chars[i])
            i += 1
        }
        if !digits.isEmpty, i + 1 < chars.count, chars[i] == ".", chars[i + 1] == " ",
           let n = Int(digits) {
            return .ordered(number: n)
        }
        // Blockquote: "> "
        if body.hasPrefix("> ") {
            return .blockquote
        }
        return nil
    }
}
