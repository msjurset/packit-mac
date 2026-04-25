import SwiftUI
import Sparkle

@main
struct PackItApp: App {
    @State private var store = PackItStore()
    @Environment(\.openWindow) private var openWindow
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    var body: some Scene {
        WindowGroup {
            RootShell {
                ContentView()
                    .onAppear { store.startBackgroundRefresh() }
                    .onDisappear { store.stopBackgroundRefresh() }
            }
            .environment(store)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            CommandGroup(replacing: .help) {
                Button("PackIt Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            RootShell { SettingsView() }
                .environment(store)
        }

        WindowGroup("PackIt Help", id: "help") {
            RootShell { HelpView() }
                .environment(store)
        }
        .defaultSize(width: 800, height: 550)
    }
}

/// Wraps a root view to observe `PackItStore` and apply user-chosen
/// preferences (color scheme, font size) reactively. Putting these in a
/// View — rather than directly on a Scene's WindowGroup — ensures the
/// modifiers actually re-apply when the store's localConfig mutates.
private struct RootShell<Content: View>: View {
    @Environment(PackItStore.self) private var store
    @ViewBuilder let content: Content

    var body: some View {
        content
            .preferredColorScheme(store.colorScheme)
            .dynamicTypeSize((store.localConfig.fontSize ?? .medium).dynamicTypeSize)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private var timer: Timer?

    init(updater: SPUUpdater) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
        canCheckForUpdates = updater.canCheckForUpdates
    }
}
