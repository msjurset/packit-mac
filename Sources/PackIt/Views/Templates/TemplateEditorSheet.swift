import SwiftUI

struct TemplateEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let template: PackingTemplate?

    @State private var name: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var newTag: String = ""

    private var isNew: Bool { template == nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Template Details") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Context Tags") {
                    FlowLayout(spacing: 6) {
                        ForEach(store.allTagNames, id: \.self) { tag in
                            TagChip(name: tag, isSelected: selectedTags.contains(tag)) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("New tag...", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addNewTag() }
                        Button("Add") { addNewTag() }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "Create" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            if let template {
                name = template.name
                selectedTags = Set(template.contextTags)
            }
        }
    }

    private func addNewTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTag(name: trimmed)
        selectedTags.insert(trimmed)
        newTag = ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var existing = template {
            existing.name = trimmedName
            existing.contextTags = Array(selectedTags).sorted()
            store.updateTemplate(existing)
        } else {
            store.createTemplate(name: trimmedName, contextTags: Array(selectedTags).sorted())
        }
        dismiss()
    }
}
