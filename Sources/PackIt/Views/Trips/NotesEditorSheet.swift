import SwiftUI
import PackItKit

struct NotesEditorSheet: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @State private var showPreview = false
    @State private var showSyntaxHelp = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Picker("", selection: $showPreview) {
                    Text("Edit").tag(false)
                    Text("Preview").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding()

            Divider()

            if showPreview {
                // Split: editor left, preview right
                HStack(spacing: 0) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)

                    Divider()

                    ScrollView {
                        if text.isEmpty {
                            Text("Start typing to see preview...")
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                                .padding(12)
                        } else {
                            renderMarkdown(text)
                                .padding(12)
                        }
                    }
                }
            } else {
                // Full editor
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }

            Divider()

            HStack {
                Text("Supports limited ")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                +
                Text("Markdown")
                    .font(.caption2)
                    .foregroundStyle(.packitTeal)

                Button {
                    showSyntaxHelp.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSyntaxHelp, arrowEdge: .top) {
                    markdownSyntaxHelp
                }

                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 700, height: 500)
    }

    @ViewBuilder
    private func renderMarkdown(_ source: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(source.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if line.hasPrefix("# ") {
                    Text(inlineMarkdown(String(line.dropFirst(2))))
                        .font(.title2.bold())
                } else if line.hasPrefix("## ") {
                    Text(inlineMarkdown(String(line.dropFirst(3))))
                        .font(.title3.bold())
                } else if line.hasPrefix("### ") {
                    Text(inlineMarkdown(String(line.dropFirst(4))))
                        .font(.headline)
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(inlineMarkdown(String(line.dropFirst(2))))
                    }
                    .font(.callout)
                } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 4)
                } else {
                    Text(inlineMarkdown(line))
                        .font(.callout)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private var markdownSyntaxHelp: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Markdown Syntax")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text(verbatim: "**bold**").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("**bold**").font(.caption)
                }
                GridRow {
                    Text(verbatim: "*italic*").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("*italic*").font(.caption)
                }
                GridRow {
                    Text(verbatim: "`code`").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("`code`").font(.caption)
                }
                GridRow {
                    Text(verbatim: "[text](url)").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("clickable link").font(.caption).foregroundStyle(.blue)
                }
                GridRow {
                    Text(verbatim: "# Heading").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("Heading").font(.caption.bold())
                }
                GridRow {
                    Text(verbatim: "## Subheading").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("Subheading").font(.caption.weight(.semibold))
                }
                GridRow {
                    Text(verbatim: "- item").font(.caption.monospaced()).foregroundStyle(.secondary)
                    HStack(spacing: 4) { Text("•").font(.caption); Text("item").font(.caption) }
                }
                GridRow {
                    Text(verbatim: "~~strike~~").font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("~~strike~~").font(.caption)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
