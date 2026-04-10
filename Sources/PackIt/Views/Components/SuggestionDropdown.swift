import SwiftUI

struct SuggestionDropdown: View {
    let items: [String]
    let selectedIndex: Int
    let onSelect: (String) -> Void
    var rowLabel: ((String) -> AnyView)?

    var body: some View {
        if items.isEmpty { EmptyView() } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, suggestion in
                            Button {
                                onSelect(suggestion)
                            } label: {
                                if let rowLabel {
                                    rowLabel(suggestion)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(index == selectedIndex ? Color.packitTeal.opacity(0.15) : .clear)
                                        .contentShape(Rectangle())
                                } else {
                                    Text(suggestion)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(index == selectedIndex ? Color.packitTeal.opacity(0.15) : .clear)
                                        .contentShape(Rectangle())
                                }
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                }
                .frame(maxHeight: min(CGFloat(items.count) * 30, 150))
                .fixedSize(horizontal: false, vertical: true)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator, lineWidth: 0.5))
                .padding(.top, 2)
                .onChange(of: selectedIndex) {
                    if selectedIndex >= 0 {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
            }
        }
    }
}
