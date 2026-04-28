import SwiftUI

struct CategoryField: View {
    @Environment(PackItStore.self) private var store
    @Binding var text: String

    @State private var isFocused = false
    @State private var state = SuggestState()
    @State private var eventMonitor: Any?

    private var filteredSuggestions: [String] {
        let query = text.lowercased()
        guard !query.isEmpty else { return store.allCategories }
        return store.allCategories.filter {
            $0.lowercased().contains(query) && $0.lowercased() != query
        }
    }

    private var displayed: [String] {
        state.displayedSuggestions(from: filteredSuggestions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LeadingTextField(label: "Category", text: $text, prompt: "Category (optional)", isFocused: $isFocused)
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
                SuggestionDropdown(items: displayed, selectedIndex: state.selectedIndex, onSelect: { suggestion in
                    acceptSuggestion(suggestion)
                }, rowLabel: { suggestion in
                    AnyView(
                        HStack(spacing: 8) {
                            Image(systemName: store.categoryIcon(for: suggestion))
                                .font(.caption)
                                .foregroundStyle(store.categoryColor(for: suggestion))
                                .frame(width: 16)
                            Text(suggestion)
                                .font(.callout)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    )
                })
            }
        }
        .onDisappear { SuggestMonitor.remove(monitor: &eventMonitor) }
    }

    private func acceptSuggestion(_ suggestion: String) {
        state.isPreviewing = true
        text = suggestion
        state.markAccepted()
    }
}
