import SwiftUI

struct PrintSettingsSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance
    @State private var config = AppConfig()
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        layoutSection
                        Divider()
                        patternSection
                        Divider()
                        fullPageSection
                        Divider()
                        borderSection
                    }
                    .padding()
                }
                .frame(width: 280)

                Divider()

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
                .frame(maxWidth: .infinity)
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                SettingsLink {
                    Label("All Settings", systemImage: "gearshape")
                }
                Button("Print...") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        PrintService.print(trip: trip, config: config)
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 620, height: 480)
        .onAppear { loadConfig() }
    }

    // MARK: - Sections

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
                case .standard: "Columns with full details and notes."
                case .compact: "Category boxes, smaller text."
                case .dense: "Maximum density, tiny text."
                }
            }())
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enablePattern) {
                Label("Repeating Pattern", systemImage: "square.grid.3x3")
                    .font(.subheadline.weight(.semibold))
            }
            .onChange(of: config.enablePattern) { _, _ in saveConfig() }

            if config.enablePattern {
                Picker("Style", selection: $config.patternStyle) {
                    ForEach(PatternStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.patternStyle) { _, _ in saveConfig() }
                opacitySlider(value: $config.patternOpacity, range: 0.02...0.15)
            }
        }
    }

    private var fullPageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enableFullPage) {
                Label("Full-Page Art", systemImage: "photo")
                    .font(.subheadline.weight(.semibold))
            }
            .onChange(of: config.enableFullPage) { _, _ in saveConfig() }

            if config.enableFullPage {
                Picker("Style", selection: $config.fullPageStyle) {
                    ForEach(FullPageStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.fullPageStyle) { _, _ in saveConfig() }
                opacitySlider(value: $config.fullPageOpacity, range: 0.02...0.12)
            }
        }
    }

    private var borderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $config.enableBorder) {
                Label("Border", systemImage: "rectangle")
                    .font(.subheadline.weight(.semibold))
            }
            .onChange(of: config.enableBorder) { _, _ in saveConfig() }

            if config.enableBorder {
                Picker("Style", selection: $config.borderStyle) {
                    ForEach(BorderStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.icon).tag(style)
                    }
                }
                .onChange(of: config.borderStyle) { _, _ in saveConfig() }
                opacitySlider(value: $config.borderOpacity, range: 0.03...0.20)
            }
        }
    }

    private func opacitySlider(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text("Opacity")
                .font(.caption)
            Slider(value: value, in: range, step: 0.01)
                .onChange(of: value.wrappedValue) { _, _ in saveConfig() }
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 30)
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
