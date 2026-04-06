import SwiftUI

struct TemplateListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @State private var editingTemplate: PackingTemplate?
    @State private var exportingTemplate: PackingTemplate?
    @State private var templateToDelete: PackingTemplate?

    var body: some View {
        @Bindable var store = store
        Group {
            if store.filteredTemplates.isEmpty && store.searchQuery.isEmpty {
                ContentUnavailableView {
                    Label("No Templates Yet", systemImage: "suitcase")
                } description: {
                    Text("Templates are reusable packing lists.\nCreate one to get started.")
                } actions: {
                    Button("Create Template") {
                        showNewTemplateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.packitTeal)
                }
            } else if store.filteredTemplates.isEmpty {
                ContentUnavailableView.search(text: store.searchQuery)
            } else {
                List {
                    ForEach(store.filteredTemplates) { template in
                        Button {
                            store.selectedTemplateID = template.id
                            store.navigation = .templateDetail(template.id)
                        } label: {
                            TemplateRow(template: template)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            store.selectedTemplateID == template.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .contextMenu {
                            Button {
                                editingTemplate = template
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                store.duplicateTemplate(id: template.id)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            Button {
                                exportingTemplate = template
                            } label: {
                                Label("Export...", systemImage: "square.and.arrow.up")
                            }
                            Divider()
                            Button(role: .destructive) {
                                templateToDelete = template
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("templateList")
        .navigationTitle("Templates")
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button { showNewTemplateSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)
                .help("New template (⌘N)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .searchable(text: $store.searchQuery, prompt: "Search templates...")
        .sheet(item: $editingTemplate) { template in
            TemplateEditorSheet(template: template)
        }
        .sheet(item: $exportingTemplate) { template in
            TemplateExportSheet(template: template)
        }
        .alert("Delete Template?", isPresented: .init(
            get: { templateToDelete != nil },
            set: { if !$0 { templateToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { templateToDelete = nil }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    store.deleteTemplate(id: template.id)
                }
                templateToDelete = nil
            }
        } message: {
            if let template = templateToDelete {
                Text("This will permanently delete \"\(template.name)\" and its \(template.itemCount) items.")
            }
        }
    }
}

struct TemplateRow: View {
    let template: PackingTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(template.name)
                    .font(.system(.body, weight: .semibold))
                Spacer()
                Text("\(template.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !template.contextTags.isEmpty {
                FlowLayout(spacing: 3) {
                    ForEach(template.contextTags, id: \.self) { tag in
                        StyledTag(name: tag, compact: true)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}
