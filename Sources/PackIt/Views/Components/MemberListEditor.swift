import SwiftUI

/// Inline editor for a trip's member list. Add by typing + Return; remove by clicking ×.
struct MemberListEditor: View {
    @Binding var members: [String]
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !members.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(members, id: \.self) { member in
                        memberChip(member)
                    }
                }
            }
            HStack(spacing: 6) {
                LeadingTextField(label: "Member", text: $newName, prompt: "Add a member (e.g. Alice)")
                    .onSubmit { commit() }
                Button("Add") { commit() }
                    .disabled(trimmed.isEmpty || isDuplicate)
                    .focusable(false)
            }
        }
    }

    private var trimmed: String {
        newName.trimmingCharacters(in: .whitespaces)
    }

    private var isDuplicate: Bool {
        members.contains { $0.lowercased() == trimmed.lowercased() }
    }

    private func commit() {
        let name = trimmed
        guard !name.isEmpty, !isDuplicate else { return }
        members.append(name)
        newName = ""
    }

    @ViewBuilder
    private func memberChip(_ name: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(.packitTeal)
                .font(.caption)
            Text(name)
                .font(.callout)
            Button {
                members.removeAll { $0 == name }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.packitTeal.opacity(0.1))
        .clipShape(Capsule())
    }
}
