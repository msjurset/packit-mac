import SwiftUI

struct TagSuggestField: View {
    @Environment(PackItStore.self) private var store
    let selectedTags: Set<String>
    var onCommit: ([String]) -> Void

    @State private var text = ""
    @State private var isFocused = false
    @State private var state = SuggestState()
    @State private var eventMonitor: Any?

    private var committedTags: Set<String> {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count > 1 else { return [] }
        return Set(parts.dropLast().map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty })
    }

    private var currentPartial: String {
        guard let lastComma = text.lastIndex(of: ",") else {
            return text.trimmingCharacters(in: .whitespaces).lowercased()
        }
        return String(text[text.index(after: lastComma)...]).trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var filteredSuggestions: [String] {
        let excluded = committedTags.union(selectedTags.map { $0.lowercased() })
        let partial = currentPartial
        let all = store.allTagNames.filter { !excluded.contains($0.lowercased()) }
        if partial.isEmpty { return all }
        return all.filter { $0.lowercased().contains(partial) }
    }

    private var displayed: [String] {
        state.displayedSuggestions(from: filteredSuggestions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                LeadingTextField(
                    label: "New tag",
                    text: $text,
                    prompt: "Comma-separated: beach, winter",
                    isFocused: $isFocused
                )
                .onChange(of: text) { state.handleTextChange() }
                .onChange(of: isFocused) {
                    if isFocused {
                        SuggestMonitor.install(
                            monitor: &eventMonitor,
                            isFocused: { [isFocused] in isFocused },
                            state: state,
                            filteredSuggestions: { [self] in filteredSuggestions },
                            displayedSuggestions: { [self] in displayed },
                            advance: { [self] delta in
                                state.advanceSelection(by: delta, in: filteredSuggestions) { preview in
                                    replaceCurrentPartial(with: preview)
                                }
                            },
                            accept: { [self] suggestion in acceptSuggestion(suggestion) },
                            onEnterFallthrough: { [self] in commitAll() }
                        )
                    } else {
                        SuggestMonitor.remove(monitor: &eventMonitor)
                        state.dismissSuggestions()
                    }
                }
                Button("Add") { commitAll() }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if isFocused && !displayed.isEmpty {
                SuggestionDropdown(items: displayed, selectedIndex: state.selectedIndex) { suggestion in
                    acceptSuggestion(suggestion)
                }
            }
        }
        .onDisappear { SuggestMonitor.remove(monitor: &eventMonitor) }
    }

    private func replaceCurrentPartial(with value: String) {
        state.isPreviewing = true
        if let lastComma = text.lastIndex(of: ",") {
            text = String(text[...lastComma]) + " " + value
        } else {
            text = value
        }
    }

    private func acceptSuggestion(_ suggestion: String) {
        replaceCurrentPartial(with: suggestion)
        state.markAccepted()
    }

    private func commitAll() {
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let valid = parts.filter { !$0.isEmpty }
        guard !valid.isEmpty else { return }
        onCommit(valid)
        text = ""
        state.reset()
    }
}
