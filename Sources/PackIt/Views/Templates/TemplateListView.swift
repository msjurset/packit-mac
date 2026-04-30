import SwiftUI
import PackItKit
import UniformTypeIdentifiers

struct TemplateListView: View {
    @Environment(PackItStore.self) private var store
    @Binding var showNewTemplateSheet: Bool
    @State private var editingTemplate: PackingTemplate?
    @State private var exportingTemplate: PackingTemplate?
    @State private var templateToDelete: PackingTemplate?
    @State private var showImporter = false

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
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(store.filteredTemplates.enumerated()), id: \.element.id) { index, template in
                            TemplateRow(
                                template: template,
                                isReceivedShare: store.isReceivedShare(templateID: template.id),
                                isSharingOut: store._sharedTemplateIDs.contains(template.id)
                            )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    store.selectedTemplateID == template.id
                                        ? Color.accentColor.opacity(0.15)
                                        : index.isMultiple(of: 2) ? Color.secondary.opacity(0.04) : Color.primary.opacity(0.001)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .onTapGesture {
                                    store.selectedTemplateID = template.id
                                    store.navigation = .templateDetail(template.id)
                                }
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
                                    Divider()
                                    shareTemplateMenu(template)
                                    Button(role: .destructive) {
                                        templateToDelete = template
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .contextMenu {
                    Button { showNewTemplateSheet = true } label: {
                        Label("New Template", systemImage: "plus")
                    }
                    Button { showImporter = true } label: {
                        Label("Import Template...", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .accessibilityIdentifier("templateList")
        .navigationTitle("Templates")
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button { showImporter = true } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .foregroundStyle(.secondary)
                .help("Import template file")
                Button { showNewTemplateSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)
                .focusable(false)
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
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType(exportedAs: "com.msjurset.packit.template"), .json], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    store.importTemplate(from: url)
                }
            }
        }
    }

    @ViewBuilder
    private func shareTemplateMenu(_ template: PackingTemplate) -> some View {
        if store.localConfig.hasSharedPath {
            if store._sharedTemplateIDs.contains(template.id) {
                Button { store.unshareTemplate(id: template.id) } label: {
                    Label("Unshare", systemImage: "person.crop.circle.badge.minus")
                }
            } else {
                Button { store.shareTemplate(id: template.id) } label: {
                    Label("Share", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct TemplateRow: View {
    let template: PackingTemplate
    var isReceivedShare: Bool = false
    var isSharingOut: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                if template.isComposite {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.packitTeal)
                }
                Text(template.name)
                    .font(.system(.body, weight: .semibold))
                if isReceivedShare {
                    SharedBadge(author: template.createdBy, compact: true)
                } else if isSharingOut {
                    SharingOutBadge(compact: true)
                }
                Spacer()
                Text(templateSummary)
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

    private var templateSummary: String {
        var parts: [String] = []
        if template.itemCount > 0 { parts.append("\(template.itemCount) items") }
        if template.prepTaskCount > 0 { parts.append("\(template.prepTaskCount) prep") }
        if !template.procedures.isEmpty {
            let totalSteps = template.procedures.reduce(0) { $0 + $1.stepCount }
            parts.append("\(template.procedures.count) procedures (\(totalSteps) steps)")
        }
        if template.isComposite { parts.append("\(template.linkedTemplateIDs.count) linked") }
        return parts.isEmpty ? "Empty" : parts.joined(separator: " · ")
    }
}
