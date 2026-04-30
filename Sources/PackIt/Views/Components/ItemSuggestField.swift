import SwiftUI
import PackItKit

struct ItemSuggestField: View {
    @Environment(PackItStore.self) private var store
    @Binding var text: String
    let excludeNames: Set<String>
    var onAccept: ((String) -> Void)?

    @State private var isFocused = false
    @State private var state = SuggestState()
    @State private var eventMonitor: Any?

    private var filteredSuggestions: [String] {
        let excludedSet = Set(excludeNames.map { $0.lowercased() })
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        let all = store.allItemNames.filter { !excludedSet.contains($0.lowercased()) }
        if q.isEmpty { return all }
        return all.filter { $0.lowercased().contains(q) }
    }

    private var displayed: [String] {
        state.displayedSuggestions(from: filteredSuggestions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LeadingTextField(label: "Name", text: $text, isFocused: $isFocused)
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
                                    state.isPreviewing = true
                                    text = preview
                                }
                            },
                            accept: { [self] suggestion in acceptSuggestion(suggestion) }
                        )
                    } else {
                        SuggestMonitor.remove(monitor: &eventMonitor)
                        state.dismissSuggestions()
                    }
                }

            if isFocused && !displayed.isEmpty {
                SuggestionDropdown(items: displayed, selectedIndex: state.selectedIndex) { suggestion in
                    acceptSuggestion(suggestion)
                }
            }
        }
        .onDisappear { SuggestMonitor.remove(monitor: &eventMonitor) }
    }

    private func acceptSuggestion(_ suggestion: String) {
        state.isPreviewing = true
        text = suggestion
        state.markAccepted()
        onAccept?(suggestion)
    }
}
