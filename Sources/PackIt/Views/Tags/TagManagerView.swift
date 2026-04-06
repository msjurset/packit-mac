import SwiftUI

struct TagManagerView: View {
    @Environment(PackItStore.self) private var store
    @State private var newTagName = ""
    @State private var renamingTag: ContextTag?
    @State private var renameText = ""

    var body: some View {
        List {
            Section {
                HStack {
                    LeadingTextField(label: "New tag", text: $newTagName, prompt: "New tag name...")
                    Button("Add") { addTag() }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Tags (\(store.tags.count))") {
                if store.tags.isEmpty {
                    Text("No tags yet. Tags help you organize template items by context (e.g., \"beach\", \"winter\", \"international\").")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.tags) { tag in
                        Button {
                            store.selectedTagID = tag.id
                        } label: {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundStyle(.blue)
                                Text(tag.name)
                                Spacer()
                                Text(templateCount(for: tag.name))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            store.selectedTagID == tag.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .contextMenu {
                            Button("Rename...") {
                                renamingTag = tag
                                renameText = tag.name
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                store.removeTag(id: tag.id)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("tagManager")
        .navigationTitle("Tags")
        .alert("Rename Tag", isPresented: .init(
            get: { renamingTag != nil },
            set: { if !$0 { renamingTag = nil } }
        )) {
            TextField("New name", text: $renameText)
            Button("Rename") {
                if let tag = renamingTag, !renameText.isEmpty {
                    store.renameTag(id: tag.id, newName: renameText)
                }
                renamingTag = nil
            }
            Button("Cancel", role: .cancel) {
                renamingTag = nil
            }
        }
    }

    private func addTag() {
        let parts = newTagName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for part in parts where !part.isEmpty {
            store.addTag(name: part)
        }
        newTagName = ""
    }

    private func templateCount(for tagName: String) -> String {
        let count = store.templates.filter { $0.contextTags.contains(tagName) }.count
        return "\(count) template\(count == 1 ? "" : "s")"
    }
}
