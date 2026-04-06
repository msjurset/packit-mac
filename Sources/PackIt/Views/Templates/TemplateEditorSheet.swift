import SwiftUI

struct TemplateEditorSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let template: PackingTemplate?

    @State private var name: String = ""
    @State private var selectedTags: Set<String> = []
    private var isNew: Bool { template == nil }

    var body: some View {
        FormSheet(width: 500, height: 400) {
            Section("Template Details") {
                LeadingTextField(label: "Name", text: $name)
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
                TagSuggestField(selectedTags: selectedTags) { tags in
                    for tag in tags {
                        store.addTag(name: tag)
                        selectedTags.insert(tag)
                    }
                }
            }
        } footer: {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button(isNew ? "Create" : "Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            if let template {
                name = template.name
                selectedTags = Set(template.contextTags)
            }
        }
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
