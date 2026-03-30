import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trip: TripInstance

    @State private var exportFormat: ExportFormat = .packitlist
    @State private var showFileSaver = false
    @State private var exportData: Data?
    @State private var exportError: String?

    enum ExportFormat: String, CaseIterable {
        case packitlist = "PackIt File (.packitlist)"
        case html = "HTML"
        case csv = "CSV"

        var utType: UTType {
            switch self {
            case .packitlist: return UTType(exportedAs: "com.msjurset.packit.list")
            case .html: return .html
            case .csv: return .commaSeparatedText
            }
        }

        var fileExtension: String {
            switch self {
            case .packitlist: return "packitlist"
            case .html: return "html"
            case .csv: return "csv"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Preview") {
                    Text("Trip: \(trip.name)")
                    Text("Items: \(trip.totalItems) (\(trip.packedCount) packed)")
                    Text("TODOs: \(trip.todos.count)")
                }

                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Export") { performExport() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 350)
        .fileExporter(
            isPresented: $showFileSaver,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat.utType,
            defaultFilename: "\(trip.name).\(exportFormat.fileExtension)"
        ) { result in
            if case .failure(let error) = result {
                exportError = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }

    private func performExport() {
        Task {
            do {
                switch exportFormat {
                case .packitlist:
                    exportData = try await store.exportTrip(trip)
                case .html:
                    exportData = generateHTML().data(using: .utf8)
                case .csv:
                    exportData = generateCSV().data(using: .utf8)
                }
                showFileSaver = true
            } catch {
                exportError = error.localizedDescription
            }
        }
    }

    private func generateHTML() -> String {
        var html = """
        <!DOCTYPE html>
        <html><head><meta charset="UTF-8">
        <title>\(trip.name) - Packing List</title>
        <style>
        body { font-family: -apple-system, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #333; }
        h1 { color: #1a7a7a; border-bottom: 2px solid #1a7a7a; padding-bottom: 8px; }
        h2 { color: #555; margin-top: 24px; }
        .meta { color: #666; font-size: 0.9em; margin-bottom: 20px; }
        .item { padding: 6px 0; border-bottom: 1px solid #eee; }
        .packed { color: #999; text-decoration: line-through; }
        .priority-high { color: #e67e22; }
        .priority-critical { color: #e74c3c; font-weight: bold; }
        .checkbox { width: 16px; height: 16px; margin-right: 8px; vertical-align: middle; }
        .todo { padding: 4px 0; }
        .notes { background: #f8f8f8; padding: 12px; border-radius: 6px; margin-top: 16px; }
        @media print { body { margin: 20px; } }
        </style></head><body>
        <h1>\(trip.name)</h1>
        <div class="meta">
        Departure: \(trip.departureDate.formatted(date: .long, time: .omitted))
        """
        if let ret = trip.returnDate {
            html += " | Return: \(ret.formatted(date: .long, time: .omitted))"
        }
        html += " | \(trip.packedCount)/\(trip.totalItems) packed</div>"

        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        for category in grouped.keys.sorted() {
            html += "<h2>\(category)</h2>"
            for item in grouped[category] ?? [] {
                let cls = item.isPacked ? "item packed" : "item"
                let priorityCls = item.priority >= .high ? " priority-\(item.priority.rawValue)" : ""
                let check = item.isPacked ? "checked" : ""
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check) disabled><span class=\"\(priorityCls)\">\(item.name)</span></div>"
            }
        }

        if !trip.todos.isEmpty {
            html += "<h2>TODOs</h2>"
            for todo in trip.todos {
                let check = todo.isComplete ? "checked" : ""
                let cls = todo.isComplete ? "todo packed" : "todo"
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check) disabled> \(todo.text)</div>"
            }
        }

        if !trip.scratchNotes.isEmpty {
            html += "<h2>Notes</h2><div class=\"notes\">\(trip.scratchNotes)</div>"
        }

        html += "</body></html>"
        return html
    }

    private func generateCSV() -> String {
        var csv = "Category,Item,Priority,Packed,Notes\n"
        for item in trip.items {
            let cat = item.category ?? ""
            let packed = item.isPacked ? "Yes" : "No"
            let notes = (item.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(cat)\",\"\(item.name)\",\"\(item.priority.label)\",\"\(packed)\",\"\(notes)\"\n"
        }
        return csv
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .html, .commaSeparatedText] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
