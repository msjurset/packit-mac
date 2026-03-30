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

    private func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func generateHTML() -> String {
        let name = esc(trip.name)
        var html = """
        <!DOCTYPE html>
        <html><head><meta charset="UTF-8">
        <title>\(name) - Packing List</title>
        <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, Helvetica Neue, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 24px; color: #2c3e50; line-height: 1.5; }
        h1 { color: #1a7a7a; border-bottom: 3px solid #1a7a7a; padding-bottom: 10px; font-size: 28px; }
        h2 { color: #1a7a7a; margin-top: 28px; font-size: 18px; border-bottom: 1px solid #e0e0e0; padding-bottom: 6px; }
        .meta { color: #7f8c8d; font-size: 14px; margin-bottom: 24px; }
        .item { padding: 8px 12px; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; }
        .item:hover { background: #f8fafa; }
        .packed { color: #95a5a6; }
        .packed span { text-decoration: line-through; }
        .priority-high span { color: #e67e22; font-weight: 500; }
        .priority-critical span { color: #e74c3c; font-weight: 600; }
        .checkbox { width: 18px; height: 18px; margin-right: 10px; accent-color: #1a7a7a; }
        .todo { padding: 6px 12px; display: flex; align-items: center; }
        .notes { background: #f7f9f9; padding: 16px; border-radius: 8px; margin-top: 16px; border: 1px solid #e8eded; white-space: pre-wrap; }
        .progress { font-size: 14px; color: #1a7a7a; font-weight: 600; }
        @media print { body { margin: 20px; font-size: 12px; } .item:hover { background: none; } }
        </style></head><body>
        <h1>\(name)</h1>
        <div class="meta">
        Departure: \(trip.departureDate.formatted(date: .long, time: .omitted))
        """
        if let ret = trip.returnDate {
            html += " &middot; Return: \(ret.formatted(date: .long, time: .omitted))"
        }
        html += " &middot; <span class=\"progress\">\(trip.packedCount)/\(trip.totalItems) packed</span></div>"

        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        for category in grouped.keys.sorted() {
            html += "<h2>\(esc(category))</h2>"
            for item in grouped[category] ?? [] {
                let cls = item.isPacked ? "item packed" : "item"
                let priorityCls = item.priority >= .high ? " priority-\(item.priority.rawValue)" : ""
                let check = item.isPacked ? "checked" : ""
                html += "<div class=\"\(cls)\(priorityCls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)><span>\(esc(item.name))</span></div>"
            }
        }

        if !trip.todos.isEmpty {
            html += "<h2>TODOs</h2>"
            for todo in trip.todos {
                let check = todo.isComplete ? "checked" : ""
                let cls = todo.isComplete ? "todo packed" : "todo"
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)> <span>\(esc(todo.text))</span></div>"
            }
        }

        if !trip.scratchNotes.isEmpty {
            html += "<h2>Notes</h2><div class=\"notes\">\(esc(trip.scratchNotes))</div>"
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
