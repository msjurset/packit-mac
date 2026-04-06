import SwiftUI

struct SettingsView: View {
    @Environment(PackItStore.self) private var store
    @State private var config = AppConfig()
    @State private var hasLoaded = false

    var body: some View {
        printSettingsTab
            .frame(width: 600, height: 580)
        .onAppear { loadConfig() }
    }

    // MARK: - Print Settings Tab

    private var printSettingsTab: some View {
        HSplitView {
            // Controls
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pattern
                    patternSection

                    Divider()

                    // Full-page Art
                    fullPageSection

                    Divider()

                    // Border
                    borderSection
                }
                .padding()
            }
            .frame(minWidth: 280, idealWidth: 300)

            // Live Preview
            VStack(spacing: 8) {
                Text("Preview")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                WatermarkPreview(config: config)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .shadow(radius: 2)
            }
            .padding()
            .frame(minWidth: 240)
        }
    }

    // MARK: - Pattern Section

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enablePattern) {
                Label("Repeating Pattern", systemImage: "square.grid.3x3")
                    .font(.headline)
            }
            .onChange(of: config.enablePattern) { _, _ in saveConfig() }

            if config.enablePattern {
                Picker("Style", selection: $config.patternStyle) {
                    ForEach(PatternStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.patternStyle) { _, _ in saveConfig() }

                HStack {
                    Text("Opacity")
                        .font(.caption)
                    Slider(value: $config.patternOpacity, in: 0.02...0.15, step: 0.01)
                        .onChange(of: config.patternOpacity) { _, _ in saveConfig() }
                    Text("\(Int(config.patternOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 30)
                }
            }
        }
    }

    // MARK: - Full-Page Section

    private var fullPageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enableFullPage) {
                Label("Full-Page Art", systemImage: "photo.artframe")
                    .font(.headline)
            }
            .onChange(of: config.enableFullPage) { _, _ in saveConfig() }

            if config.enableFullPage {
                Picker("Style", selection: $config.fullPageStyle) {
                    ForEach(FullPageStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.fullPageStyle) { _, _ in saveConfig() }

                HStack {
                    Text("Opacity")
                        .font(.caption)
                    Slider(value: $config.fullPageOpacity, in: 0.02...0.12, step: 0.01)
                        .onChange(of: config.fullPageOpacity) { _, _ in saveConfig() }
                    Text("\(Int(config.fullPageOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 30)
                }
            }
        }
    }

    // MARK: - Border Section

    private var borderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enableBorder) {
                Label("Border", systemImage: "rectangle")
                    .font(.headline)
            }
            .onChange(of: config.enableBorder) { _, _ in saveConfig() }

            if config.enableBorder {
                Picker("Style", selection: $config.borderStyle) {
                    ForEach(BorderStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.borderStyle) { _, _ in saveConfig() }

                HStack {
                    Text("Opacity")
                        .font(.caption)
                    Slider(value: $config.borderOpacity, in: 0.03...0.20, step: 0.01)
                        .onChange(of: config.borderOpacity) { _, _ in saveConfig() }
                    Text("\(Int(config.borderOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 30)
                }
            }
        }
    }

    // MARK: - Persistence

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

// MARK: - Combined Preview

struct WatermarkPreview: View {
    let config: AppConfig

    var body: some View {
        Canvas { context, size in
            // White page
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

            // Render all watermark layers (flip CG context to match bottom-left origin)
            context.withCGContext { cgContext in
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: size.height)
                cgContext.scaleBy(x: 1, y: -1)
                WatermarkRenderer.draw(config: config, in: CGRect(origin: .zero, size: size), context: cgContext)
                cgContext.restoreGState()
            }

            // Simulated text lines (SwiftUI Canvas coordinates: y=0 at top)
            let textColor = Color.black.opacity(0.5)
            // Title
            context.fill(Path(CGRect(x: 20, y: 20, width: 120, height: 10)), with: .color(textColor.opacity(0.3)))
            // Subtitle
            context.fill(Path(CGRect(x: 20, y: 36, width: 80, height: 6)), with: .color(textColor.opacity(0.15)))
            // Category headers + items
            let cols = 3
            let colW = (size.width - 50) / CGFloat(cols)
            for col in 0..<cols {
                let cx = 20 + CGFloat(col) * colW
                // Header
                context.fill(Path(CGRect(x: cx, y: 55, width: colW * 0.6, height: 6)), with: .color(textColor.opacity(0.2)))
                // Items
                for i in 0..<6 {
                    let iy = 70 + CGFloat(i) * 14
                    guard iy < size.height - 10 else { break }
                    // Checkbox circle
                    context.stroke(Path(ellipseIn: CGRect(x: cx, y: iy, width: 6, height: 6)), with: .color(textColor.opacity(0.2)), lineWidth: 0.5)
                    // Text line
                    let w = [colW * 0.5, colW * 0.7, colW * 0.4, colW * 0.6, colW * 0.55, colW * 0.45][i]
                    context.fill(Path(CGRect(x: cx + 10, y: iy + 1, width: w, height: 4)), with: .color(textColor.opacity(0.12)))
                }
            }
        }
        .frame(minHeight: 200)
    }
}
