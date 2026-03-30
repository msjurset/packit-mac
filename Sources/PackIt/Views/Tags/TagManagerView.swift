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
                    TextField("New tag name...", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTag() }
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
                        HStack {
                            Image(systemName: "tag")
                                .foregroundStyle(.blue)
                            Text(tag.name)
                            Spacer()
                            Text(templateCount(for: tag.name))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTag(name: trimmed)
        newTagName = ""
    }

    private func templateCount(for tagName: String) -> String {
        let count = store.templates.filter { $0.contextTags.contains(tagName) }.count
        return "\(count) template\(count == 1 ? "" : "s")"
    }
}
