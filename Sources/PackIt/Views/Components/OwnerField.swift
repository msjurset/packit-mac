import SwiftUI

struct OwnerField: View {
    @Environment(PackItStore.self) private var store
    @Binding var text: String

    @State private var isFocused = false
    @State private var state = SuggestState()
    @State private var eventMonitor: Any?

    private var filteredSuggestions: [String] {
        let query = text.lowercased()
        let all = store.allOwners
        guard !query.isEmpty else { return all }
        return all.filter { $0.lowercased().contains(query) && $0.lowercased() != query }
    }

    private var displayed: [String] {
        state.displayedSuggestions(from: filteredSuggestions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LeadingTextField(label: "Owner", text: $text, prompt: "e.g. Alice, Bob", isFocused: $isFocused)
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
                            accept: { [self] suggestion in
                                state.isPreviewing = true
                                text = suggestion
                                state.markAccepted()
                            }
                        )
                    } else {
                        SuggestMonitor.remove(monitor: &eventMonitor)
                        state.dismissSuggestions()
                    }
                }

            if isFocused && !displayed.isEmpty {
                SuggestionDropdown(items: displayed, selectedIndex: state.selectedIndex) { suggestion in
                    state.isPreviewing = true
                    text = suggestion
                    state.markAccepted()
                }
            }
        }
        .onDisappear { SuggestMonitor.remove(monitor: &eventMonitor) }
    }
}
