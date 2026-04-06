import AppKit

@MainActor
enum SuggestMonitor {
    static func install(
        monitor: inout Any?,
        isFocused: @escaping @MainActor () -> Bool,
        state: SuggestState,
        filteredSuggestions: @escaping @MainActor () -> [String],
        displayedSuggestions: @escaping @MainActor () -> [String],
        advance: @escaping @MainActor (Int) -> Void,
        accept: @escaping @MainActor (String) -> Void,
        onEnterFallthrough: (@MainActor () -> Void)? = nil
    ) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isFocused() else { return event }

            // Tab (Shift-Tab reverses), pass through after accept
            if event.keyCode == 48 {
                if state.justAccepted { return event }
                let pool = state.cyclePool ?? filteredSuggestions()
                if !pool.isEmpty {
                    advance(event.modifierFlags.contains(.shift) ? -1 : 1)
                    return nil
                }
                return event
            }

            // Down arrow or Ctrl-J
            if event.keyCode == 125 || (event.modifierFlags.contains(.control) && event.charactersIgnoringModifiers == "j") {
                let pool = state.cyclePool ?? filteredSuggestions()
                if !pool.isEmpty {
                    advance(1)
                    return nil
                }
                return event
            }

            // Up arrow or Ctrl-K
            if event.keyCode == 126 || (event.modifierFlags.contains(.control) && event.charactersIgnoringModifiers == "k") {
                let pool = state.cyclePool ?? filteredSuggestions()
                if !pool.isEmpty {
                    advance(-1)
                    return nil
                }
                return event
            }

            // Escape
            if event.keyCode == 53 {
                let displayed = displayedSuggestions()
                if state.showSuggestions && !displayed.isEmpty {
                    state.dismissSuggestions()
                    return nil
                }
                return event
            }

            // Enter
            if event.keyCode == 36 {
                let displayed = displayedSuggestions()
                if state.justAccepted || displayed.isEmpty {
                    onEnterFallthrough?()
                    return onEnterFallthrough != nil ? nil : event
                }
                if state.selectedIndex >= 0 && state.selectedIndex < displayed.count {
                    accept(displayed[state.selectedIndex])
                    return nil
                }
                return event
            }

            return event
        }
    }

    static func remove(monitor: inout Any?) {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
