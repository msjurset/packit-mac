import SwiftUI

struct WisdomBanner: View {
    @State private var currentWisdom: TravelWisdom = TravelWisdom.all.randomElement()!
    @State private var isVisible = true
    @State private var timer: Timer?

    var rotationInterval: TimeInterval = 30

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: currentWisdom.type == .tip ? "lightbulb.fill" : "quote.opening")
                .font(.caption)
                .foregroundStyle(currentWisdom.type == .tip ? .packitAmber : .packitTeal)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentWisdom.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let attribution = currentWisdom.attribution {
                    Text("— \(attribution)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    advance()
                }
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Next tip")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .id(currentWisdom.id)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func advance() {
        var next: TravelWisdom
        repeat {
            next = TravelWisdom.all.randomElement()!
        } while next.text == currentWisdom.text
        currentWisdom = next
        restartTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    advance()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        stopTimer()
        startTimer()
    }
}
