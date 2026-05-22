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
                HStack(spacing: 0) {
                    MarkdownTextView(text: $text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                    Divider()

                    ScrollView {
                        if text.isEmpty {
                            Text("Start typing to see preview...")
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            MarkdownPreview(source: text)
                                .padding(12)
                        }
                    }
                }
            } else {
                MarkdownTextView(text: $text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
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
                    MarkdownSyntaxHelp()
                }

                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 700, height: 500)
    }
}

// MARK: - Cheat sheet

private struct MarkdownSyntaxHelp: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Markdown Syntax")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                row("# Heading 1", AnyView(Text("Heading 1").font(.caption.bold())))
                row("## Heading 2", AnyView(Text("Heading 2").font(.caption.weight(.semibold))))
                row("### Heading 3", AnyView(Text("Heading 3").font(.caption.weight(.medium))))
                row("**bold**", AnyView(Text("**bold**").font(.caption)))
                row("*italic*", AnyView(Text("*italic*").font(.caption)))
                row("~~strike~~", AnyView(Text("~~strike~~").font(.caption)))
                row("`code`", AnyView(Text("`code`").font(.caption)))
                row("[text](url)", AnyView(Text("clickable link").font(.caption).foregroundStyle(.blue)))
                row("- item", AnyView(HStack(spacing: 4) { Text("•").font(.caption); Text("item").font(.caption) }))
                row("1. item", AnyView(HStack(spacing: 4) { Text("1.").font(.caption.monospacedDigit()); Text("item").font(.caption) }))
                row("- [ ] task", AnyView(HStack(spacing: 4) {
                    Image(systemName: "square").font(.caption2)
                    Text("task").font(.caption)
                }))
                row("- [x] done", AnyView(HStack(spacing: 4) {
                    Image(systemName: "checkmark.square.fill").font(.caption2).foregroundStyle(.packitTeal)
                    Text("done").font(.caption).strikethrough()
                }))
                row("> quote", AnyView(
                    HStack(spacing: 6) {
                        Rectangle().fill(Color.secondary.opacity(0.4)).frame(width: 2, height: 12)
                        Text("quote").font(.caption.italic()).foregroundStyle(.secondary)
                    }
                ))
                row("```", AnyView(Text("fenced code block").font(.caption2).foregroundStyle(.secondary)))
                row("---", AnyView(Rectangle().fill(Color.secondary.opacity(0.4)).frame(height: 1)))
            }

            Divider().padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Enter")
                    .font(.caption.bold())
                Text("Continues lists and quotes automatically. Press Enter on an empty list item to exit the list.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    @ViewBuilder
    private func row(_ syntax: String, _ rendered: AnyView) -> some View {
        GridRow {
            Text(verbatim: syntax)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            rendered
        }
    }
}
