import SwiftUI

struct SettingsView: View {
    @Environment(PackItStore.self) private var store
    @State private var config = AppConfig()
    @State private var hasLoaded = false

    var body: some View {
        Form {
            Section("Printing") {
                Toggle("Print with watermark", isOn: $config.printWithWatermark)

                if config.printWithWatermark {
                    Picker("Watermark Style", selection: $config.watermarkStyle) {
                        ForEach(WatermarkStyle.allCases) { style in
                            Label(style.displayName, systemImage: style.icon)
                                .tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    WatermarkPreview(style: config.watermarkStyle)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.separator, lineWidth: 0.5)
                        )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: config.printWithWatermark ? 500 : 200)
        .navigationTitle("Settings")
        .onAppear { loadConfig() }
        .onChange(of: config.watermarkStyle) { _, _ in saveConfig() }
        .onChange(of: config.printWithWatermark) { _, _ in saveConfig() }
    }

    private func loadConfig() {
        guard !hasLoaded else { return }
        hasLoaded = true
        Task {
            if let loaded = try? await store.loadConfig() {
                config = loaded
            }
        }
    }

    private func saveConfig() {
        Task {
            try? await store.saveConfig(config)
        }
    }
}

struct WatermarkPreview: View {
    let style: WatermarkStyle

    var body: some View {
        Canvas { context, size in
            // White background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

            // Watermark
            context.withCGContext { cgContext in
                WatermarkRenderer.draw(style: style, in: CGRect(origin: .zero, size: size), context: cgContext)
            }

            // Sample text lines to show readability
            let textColor = Color.black.opacity(0.6)
            for i in 0..<5 {
                let y = 20 + Double(i) * 20
                let width = [180.0, 140.0, 200.0, 120.0, 160.0][i]
                let rect = CGRect(x: 20, y: y, width: width, height: 8)
                context.fill(Path(rect), with: .color(textColor.opacity(0.15)))
            }
        }
    }
}
