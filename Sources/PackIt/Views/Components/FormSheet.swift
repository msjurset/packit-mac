import SwiftUI

struct FormSheet<Content: View, Footer: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            Form {
                content()
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                footer()
            }
            .padding()
        }
        .frame(width: width, height: height)
    }
}
