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
                    // Layout
                    layoutSection

                    Divider()

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

    // MARK: - Layout Section

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Print Layout", systemImage: "doc.richtext")
                .font(.headline)

            Picker("Layout", selection: $config.printLayout) {
                ForEach(PrintLayout.allCases) { layout in
                    Label(layout.displayName, systemImage: layout.icon).tag(layout)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: config.printLayout) { _, _ in saveConfig() }

            Text({
                switch config.printLayout {
                case .standard: "Items in columns with full details, notes, and spacing."
                case .compact: "Category boxes with smaller text for more items per page."
                case .dense: "Maximum density — tiny text, more columns, minimal whitespace."
                }
            }())
                .font(.caption)
                .foregroundStyle(.secondary)
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
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

            context.withCGContext { cgContext in
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: size.height)
                cgContext.scaleBy(x: 1, y: -1)
                WatermarkRenderer.draw(config: config, in: CGRect(origin: .zero, size: size), context: cgContext)
                cgContext.restoreGState()
            }

            switch config.printLayout {
            case .standard:
                drawStandardPreview(context: &context, size: size)
            case .compact:
                drawBoxPreview(context: &context, size: size, cols: 3, itemH: 10, checkSize: 5, fontSize: 4, boxPad: 5, boxGap: 5, itemsPerBox: [5, 3, 4, 6, 3, 4, 5, 3])
            case .dense:
                drawBoxPreview(context: &context, size: size, cols: 5, itemH: 7, checkSize: 3.5, fontSize: 3, boxPad: 3, boxGap: 3, itemsPerBox: [4, 3, 5, 3, 4, 3, 5, 4, 3, 4, 3, 5])
            }
        }
        .frame(minHeight: 200)
    }

    private func drawStandardPreview(context: inout GraphicsContext, size: CGSize) {
        let textColor = Color.black.opacity(0.5)
        context.fill(Path(CGRect(x: 20, y: 20, width: 120, height: 10)), with: .color(textColor.opacity(0.3)))
        context.fill(Path(CGRect(x: 20, y: 36, width: 80, height: 6)), with: .color(textColor.opacity(0.15)))

        let cols = 3
        let colW = (size.width - 50) / CGFloat(cols)
        for col in 0..<cols {
            let cx = 20 + CGFloat(col) * colW
            context.fill(Path(CGRect(x: cx, y: 55, width: colW * 0.6, height: 6)), with: .color(textColor.opacity(0.2)))
            for i in 0..<6 {
                let iy = 70 + CGFloat(i) * 14
                guard iy < size.height - 10 else { break }
                context.stroke(Path(ellipseIn: CGRect(x: cx, y: iy, width: 6, height: 6)), with: .color(textColor.opacity(0.2)), lineWidth: 0.5)
                let w = [colW * 0.5, colW * 0.7, colW * 0.4, colW * 0.6, colW * 0.55, colW * 0.45][i]
                context.fill(Path(CGRect(x: cx + 10, y: iy + 1, width: w, height: 4)), with: .color(textColor.opacity(0.12)))
            }
        }
    }

    private func drawBoxPreview(context: inout GraphicsContext, size: CGSize, cols: Int, itemH: CGFloat, checkSize: CGFloat, fontSize: CGFloat, boxPad: CGFloat, boxGap: CGFloat, itemsPerBox: [Int]) {
        let textColor = Color.black.opacity(0.5)
        // Smaller header
        let headerScale: CGFloat = cols >= 5 ? 0.6 : 0.8
        context.fill(Path(CGRect(x: 14, y: 14, width: 90 * headerScale, height: 8 * headerScale)), with: .color(textColor.opacity(0.3)))
        context.fill(Path(CGRect(x: 14, y: 14 + 12 * headerScale, width: 55 * headerScale, height: 5 * headerScale)), with: .color(textColor.opacity(0.15)))

        let startY: CGFloat = 14 + 26 * headerScale
        let margin: CGFloat = cols >= 5 ? 8 : 14
        let colW = (size.width - margin * 2 - boxGap * CGFloat(cols - 1)) / CGFloat(cols)

        // Place boxes in shortest-column-first order
        var colHeights = [CGFloat](repeating: startY, count: cols)
        let boxColor = Color.black.opacity(0.03)
        let borderColor = Color.black.opacity(0.08)
        let widths: [CGFloat] = [0.5, 0.7, 0.4, 0.6, 0.55, 0.45, 0.65, 0.5]

        for boxIdx in 0..<itemsPerBox.count {
            let minCol = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            let bx = margin + CGFloat(minCol) * (colW + boxGap)
            let by = colHeights[minCol]
            let items = itemsPerBox[boxIdx]
            let boxH = boxPad * 2 + 10 + CGFloat(items) * itemH

            guard by + boxH < size.height - 6 else { continue }

            // Box background
            let boxRect = CGRect(x: bx, y: by, width: colW, height: boxH)
            let boxPath = Path(roundedRect: boxRect, cornerRadius: 2)
            context.fill(boxPath, with: .color(boxColor))
            context.stroke(boxPath, with: .color(borderColor), lineWidth: 0.4)

            // Category header line
            context.fill(Path(CGRect(x: bx + boxPad, y: by + boxPad, width: colW * 0.5, height: fontSize + 1)), with: .color(textColor.opacity(0.18)))

            // Items
            let itemStart = by + boxPad + fontSize + 5
            for i in 0..<items {
                let iy = itemStart + CGFloat(i) * itemH
                context.stroke(Path(ellipseIn: CGRect(x: bx + boxPad, y: iy, width: checkSize, height: checkSize)), with: .color(textColor.opacity(0.15)), lineWidth: 0.3)
                let w = widths[i % widths.count] * (colW - boxPad * 2 - checkSize - 6)
                context.fill(Path(CGRect(x: bx + boxPad + checkSize + 4, y: iy + 0.5, width: w, height: fontSize)), with: .color(textColor.opacity(0.1)))
            }

            colHeights[minCol] = by + boxH + boxGap
        }
    }
}
