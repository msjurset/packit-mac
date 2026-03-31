import SwiftUI

@main
struct PackItApp: App {
    @State private var store = PackItStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .help) {
                Button("PackIt Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(store)
        }

        WindowGroup("PackIt Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 800, height: 550)
    }
}
