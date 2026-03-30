import SwiftUI

struct TemplateListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @State private var editingTemplate: PackingTemplate?
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
                List(selection: $store.selectedTemplateID) {
                    ForEach(store.filteredTemplates) { template in
                        TemplateRow(template: template)
                            .tag(template.id)
                            .contextMenu {
                                Button {
                                    editingTemplate = template
                                } label: {
                                    Label("Edit", systemImage: "pencil")
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
        .navigationTitle("Templates")
        .searchable(text: $store.searchQuery, prompt: "Search templates...")
        .sheet(item: $editingTemplate) { template in
            TemplateEditorSheet(template: template)
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
                HStack(spacing: 3) {
                    ForEach(template.contextTags.prefix(3), id: \.self) { tag in
                        StyledTag(name: tag, compact: true)
                    }
                    if template.contextTags.count > 3 {
                        Text("+\(template.contextTags.count - 3)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}
