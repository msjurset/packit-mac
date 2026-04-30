import SwiftUI
import PackItKit

struct WisdomBanner: View {
    @State private var currentWisdom: TravelWisdom = TravelWisdom.all.randomElement()!
    @State private var timer: Timer?

    var rotationInterval: TimeInterval = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: currentWisdom.type == .tip ? "lightbulb.fill" : "quote.opening")
                    .font(.body)
                    .foregroundStyle(currentWisdom.type == .tip ? .packitAmber : .packitTeal)

                Text(currentWisdom.type == .tip ? "Packing Tip" : "Travel Quote")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(currentWisdom.type == .tip ? .packitAmber : .packitTeal)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        advance()
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Next")
            }

            Text(currentWisdom.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let attribution = currentWisdom.attribution {
                Text("— \(attribution)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
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
