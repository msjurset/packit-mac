import SwiftUI
import PackItKit

@Observable
@MainActor
final class SuggestState {
    var selectedIndex: Int = -1
    var showSuggestions = true
    var justAccepted = false
    var isPreviewing = false
    var cyclePool: [String]?

    func reset() {
        selectedIndex = -1
        showSuggestions = true
        justAccepted = false
        isPreviewing = false
        cyclePool = nil
    }

    func dismissSuggestions() {
        showSuggestions = false
        selectedIndex = -1
        cyclePool = nil
    }

    func markAccepted() {
        selectedIndex = -1
        showSuggestions = false
        justAccepted = true
        cyclePool = nil
    }

    func handleTextChange() {
        if isPreviewing {
            isPreviewing = false
            return
        }
        selectedIndex = -1
        showSuggestions = true
        justAccepted = false
        cyclePool = nil
    }

    func advanceSelection(by delta: Int, in suggestions: [String], preview: (String) -> Void) {
        if cyclePool == nil {
            let pool = Array(suggestions.prefix(8))
            guard !pool.isEmpty else { return }
            cyclePool = pool
        }
        let pool = cyclePool!
        let count = pool.count
        showSuggestions = true
        let newIndex: Int
        if selectedIndex < 0 {
            newIndex = delta > 0 ? 0 : count - 1
        } else {
            newIndex = (selectedIndex + delta + count) % count
        }
        selectedIndex = newIndex
        preview(pool[newIndex])
    }

    func displayedSuggestions(from filtered: [String]) -> [String] {
        guard showSuggestions else { return [] }
        return Array((cyclePool ?? filtered).prefix(8))
    }
}
