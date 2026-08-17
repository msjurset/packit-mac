import SwiftUI

/// Shared markdown renderer used by the Notes editor's side-by-side
/// preview AND the trip inspector's collapsed Notes section. Supports
/// headings, ordered/unordered/task lists, block quotes, horizontal
/// rules, and fenced code blocks. Each list item uses an HStack so
/// wrapped lines hang-indent under the text column.
struct MarkdownPreview: View {
    enum Style {
        /// Full-size preview (Notes sheet split view).
        case standard
        /// Compact preview (trip inspector). Tighter spacing + smaller fonts.
        case compact
    }

    let source: String
    var style: Style = .standard

    var body: some View {
        if style == .standard {
            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 3) {
                content
            }
            .textSelection(.disabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
            renderBlock(block)
        }
    }

    // MARK: Block model

    private enum Block {
        case heading(level: Int, text: String)
        case unordered(text: String, indent: Int)
        case ordered(number: Int, text: String, indent: Int)
        case task(text: String, checked: Bool, indent: Int)
        case quote(text: String)
        case rule
        case codeBlock(lines: [String])
        case paragraph(text: String)
        case blank
    }

    private var blocks: [Block] {
        var out: [Block] = []
        var inCode = false
        var codeBuffer: [String] = []
        for raw in source.components(separatedBy: "\n") {
            if raw.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    out.append(.codeBlock(lines: codeBuffer))
                    codeBuffer.removeAll()
                    inCode = false
                } else {
                    inCode = true
                }
                continue
            }
            if inCode {
                codeBuffer.append(raw)
                continue
            }

            let leadingWS = raw.prefix(while: { $0 == " " || $0 == "\t" })
            let indentCols = leadingWS.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
            let indentSteps = max(0, min(indentCols / 2, 4))
            let body = String(raw.dropFirst(leadingWS.count))
            let trimmed = body.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                out.append(.blank)
                continue
            }

            if isHorizontalRule(trimmed) {
                out.append(.rule)
                continue
            }

            if let (level, headingText) = matchHeading(body) {
                out.append(.heading(level: level, text: headingText))
                continue
            }

            if let parsed = parseListLine(body) {
                switch parsed {
                case .task(let text, let checked):
                    out.append(.task(text: text, checked: checked, indent: indentSteps))
                case .unordered(let text):
                    out.append(.unordered(text: text, indent: indentSteps))
                case .ordered(let number, let text):
                    out.append(.ordered(number: number, text: text, indent: indentSteps))
                }
                continue
            }

            if body.hasPrefix("> ") {
                out.append(.quote(text: String(body.dropFirst(2))))
                continue
            }

            out.append(.paragraph(text: raw))
        }
        if inCode && !codeBuffer.isEmpty {
            out.append(.codeBlock(lines: codeBuffer))
        }
        return out
    }

    private enum ParsedListLine {
        case task(text: String, checked: Bool)
        case unordered(text: String)
        case ordered(number: Int, text: String)
    }

    private func parseListLine(_ body: String) -> ParsedListLine? {
        let chars = Array(body)
        if chars.count >= 6,
           let marker = chars.first,
           "-*+".contains(marker),
           chars[1] == " ",
           chars[2] == "[",
           "xX ".contains(chars[3]),
           chars[4] == "]",
           chars[5] == " " {
            let text = String(chars[6...])
            return .task(text: text, checked: chars[3].lowercased() == "x")
        }
        if chars.count >= 2, let marker = chars.first, "-*+".contains(marker), chars[1] == " " {
            return .unordered(text: String(chars[2...]))
        }
        var digits = ""
        var i = 0
        while i < chars.count, chars[i].isASCII, chars[i].isNumber {
            digits.append(chars[i])
            i += 1
        }
        if !digits.isEmpty, i + 1 < chars.count, chars[i] == ".", chars[i + 1] == " ",
           let n = Int(digits) {
            return .ordered(number: n, text: String(chars[(i + 2)...]))
        }
        return nil
    }

    private func matchHeading(_ body: String) -> (Int, String)? {
        let hashes = body.prefix(while: { $0 == "#" })
        let level = hashes.count
        guard level >= 1 && level <= 6 else { return nil }
        let rest = body.dropFirst(level)
        guard rest.first == " " else { return nil }
        return (level, String(rest.dropFirst()))
    }

    private func isHorizontalRule(_ s: String) -> Bool {
        let stripped = s.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 3 else { return false }
        return stripped.allSatisfy { $0 == "-" } || stripped.allSatisfy { $0 == "*" } || stripped.allSatisfy { $0 == "_" }
    }

    // MARK: Block rendering

    private var bodyFont: Font {
        style == .compact ? .caption : .callout
    }

    private var indentStep: CGFloat {
        style == .compact ? 12 : 16
    }

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inline(text))
                .font(headingFont(level))
        case .unordered(let text, let indent):
            HStack(alignment: .top, spacing: 6) {
                Text(indent == 0 ? "•" : "◦")
                    .foregroundStyle(.secondary)
                Text(inline(text))
            }
            .font(bodyFont)
            .padding(.leading, CGFloat(indent) * indentStep)
        case .ordered(let number, let text, let indent):
            HStack(alignment: .top, spacing: 6) {
                Text("\(number).")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(inline(text))
            }
            .font(bodyFont)
            .padding(.leading, CGFloat(indent) * indentStep)
        case .task(let text, let checked, let indent):
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(checked ? Color.packitTeal : .secondary)
                Text(inline(text))
                    .strikethrough(checked, color: .secondary)
                    .foregroundStyle(checked ? .secondary : .primary)
            }
            .font(bodyFont)
            .padding(.leading, CGFloat(indent) * indentStep)
        case .quote(let text):
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 3)
                Text(inline(text))
                    .padding(.leading, 8)
                    .foregroundStyle(.secondary)
            }
            .font(bodyFont.italic())
            .fixedSize(horizontal: false, vertical: true)
        case .rule:
            Divider()
                .padding(.vertical, 2)
        case .codeBlock(let lines):
            Text(lines.joined(separator: "\n"))
                .font(.system(style == .compact ? .caption2 : .caption, design: .monospaced))
                .padding(style == .compact ? 6 : 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .paragraph(let text):
            Text(inline(text))
                .font(bodyFont)
        case .blank:
            Spacer().frame(height: style == .compact ? 2 : 4)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        if style == .compact {
            switch level {
            case 1: return .subheadline.bold()
            case 2: return .callout.bold()
            case 3: return .callout.weight(.semibold)
            case 4: return .caption.weight(.semibold)
            case 5: return .caption.weight(.medium)
            default: return .caption2.weight(.medium)
            }
        }
        switch level {
        case 1: return .title2.bold()
        case 2: return .title3.bold()
        case 3: return .headline
        case 4: return .subheadline.weight(.semibold)
        case 5: return .callout.weight(.semibold)
        default: return .callout.weight(.medium)
        }
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}
