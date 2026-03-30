import SwiftUI

struct TemplateListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @State private var editingTemplate: PackingTemplate?

    var body: some View {
        Group {
            if store.filteredTemplates.isEmpty {
                ContentUnavailableView {
                    Label("No Templates", systemImage: "doc.on.doc")
                } description: {
                    Text("Create a packing list template to get started.")
                } actions: {
                    Button("New Template") {
                        showNewTemplateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(store.filteredTemplates) { template in
                        TemplateRow(template: template)
                            .tag(NavigationItem.templateDetail(template.id))
                            .contextMenu {
                                Button("Edit") {
                                    editingTemplate = template
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    store.deleteTemplate(id: template.id)
                                }
                            }
                            .onTapGesture(count: 1) {
                                store.navigation = .templateDetail(template.id)
                                store.selectedTemplateID = template.id
                            }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .searchable(text: Bindable(store).searchQuery, prompt: "Search templates...")
        .sheet(item: $editingTemplate) { template in
            TemplateEditorSheet(template: template)
        }
    }
}

struct TemplateRow: View {
    let template: PackingTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            HStack(spacing: 8) {
                Text("\(template.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !template.contextTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(template.contextTags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        if template.contextTags.count > 3 {
                            Text("+\(template.contextTags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
