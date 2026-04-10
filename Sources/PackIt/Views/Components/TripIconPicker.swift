import SwiftUI

struct TripIconPicker: View {
    @Binding var selection: TripIcon
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            TripIconView(icon: selection, size: 36)
        }
        .buttonStyle(.plain)
        .help("Choose trip icon")
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 4), spacing: 8) {
                ForEach(TripIcon.allCases) { icon in
                    Button {
                        selection = icon
                        showPicker = false
                    } label: {
                        VStack(spacing: 2) {
                            TripIconView(icon: icon, size: 32)
                            Text(icon.label)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .padding(4)
                        .background(selection == icon ? icon.color.opacity(0.1) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .frame(width: 220)
        }
    }
}
