import SwiftUI
import PackItKit

struct InlineTagEditor: View {
    @Environment(PackItStore.self) private var store
    let tags: [String]
    @Binding var isAddingTag: Bool
    @Binding var newTagText: String
    var onAdd: (String) -> Void
    var onRemove: ((String) -> Void)?
    @FocusState private var fieldFocused: Bool

    private var suggestions: [String] {
        let existing = Set(tags.map { $0.lowercased() })
        let query = newTagText.lowercased()
        let allTags = store.allTagNames
        if query.isEmpty {
            return allTags.filter { !existing.contains($0.lowercased()) }
        }
        return allTags.filter {
            $0.lowercased().contains(query) && !existing.contains($0.lowercased())
        }
    }

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(tags, id: \.self) { tag in
                if let onRemove {
                    StyledTag(name: tag)
                        .contextMenu {
                            Button("Remove Tag", role: .destructive) {
                                onRemove(tag)
                            }
                        }
                } else {
                    StyledTag(name: tag)
                }
            }

            if isAddingTag {
                tagInputField
            } else {
                Button {
                    isAddingTag = true
                    newTagText = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        fieldFocused = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.packitTeal)
                        .frame(width: 22, height: 22)
                        .background(Color.packitTeal.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Add tag")
            }
        }
    }

    private var tagInputField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                TextField("tag name", text: $newTagText)
                    .textFieldStyle(.plain)
                    .font(.caption2.weight(.medium))
                    .frame(width: 90)
                    .focused($fieldFocused)
                    .onSubmit { commitTag() }
                    .onExitCommand { cancelAdd() }

                Button {
                    commitTag()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.packitTeal)
                }
                .buttonStyle(.plain)
                .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    cancelAdd()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.packitTeal.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.packitTeal.opacity(0.3), lineWidth: 0.5))

            if !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions.prefix(8), id: \.self) { suggestion in
                            Button {
                                newTagText = suggestion
                                commitTag()
                            } label: {
                                Text(suggestion)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )
                .padding(.top, 2)
            }
        }
    }

    private func commitTag() {
        let parts = newTagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for part in parts where !part.isEmpty {
            onAdd(part)
        }
        newTagText = ""
        isAddingTag = false
    }

    private func cancelAdd() {
        newTagText = ""
        isAddingTag = false
    }
}
