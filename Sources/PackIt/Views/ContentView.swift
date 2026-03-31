import SwiftUI

struct ContentView: View {
    @Environment(PackItStore.self) private var store
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showNewTemplateSheet = false
    @State private var showNewTripSheet = false
    @State private var showQuickSearch = false

    var body: some View {
        @Bindable var store = store
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $store.navigation)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            ContentListView(
                showNewTemplateSheet: $showNewTemplateSheet,
                showNewTripSheet: $showNewTripSheet
            )
        } detail: {
            DetailView()
        }
        .onAppear {
            store.loadAll()
        }
        .onChange(of: store.navigation) { oldVal, newVal in
            let oldSection = sidebarSection(oldVal)
            let newSection = sidebarSection(newVal)
            if oldSection != newSection {
                if newSection != "templates" {
                    store.selectedTemplateID = nil
                }
                if newSection != "trips" {
                    store.selectedTripID = nil
                }
            }
        }
        .onOpenURL { url in
            if url.pathExtension == "packitlist" {
                store.importTrip(from: url)
            }
        }
        .sheet(isPresented: $showNewTemplateSheet) {
            TemplateEditorSheet(template: nil)
        }
        .sheet(isPresented: $showNewTripSheet) {
            NewTripSheet()
        }
        .sheet(isPresented: $showQuickSearch) {
            SearchView()
        }
        .keyboardShortcut("n", modifiers: .command) {
            showNewTemplateSheet = true
        }
        .keyboardShortcut("n", modifiers: [.command, .shift]) {
            showNewTripSheet = true
        }
        .keyboardShortcut("k", modifiers: .command) {
            showQuickSearch = true
        }
        .frame(minWidth: 900, minHeight: 500)
        .overlay(alignment: .top) {
            if let error = store.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.callout)
                    Spacer()
                    Button("Dismiss") {
                        store.error = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 4)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: store.error)
            }
        }
    }

    private func sidebarSection(_ item: NavigationItem?) -> String {
        switch item {
        case .templates, .templateDetail: return "templates"
        case .tripsPlanning, .tripsActive, .tripsCompleted, .tripsArchived, .tripDetail: return "trips"
        case .tags: return "tags"
        case .search: return "search"
        case nil: return ""
        }
    }
}

private extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        background(
            Button("") { action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .hidden()
        )
    }
}
