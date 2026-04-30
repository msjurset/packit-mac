import SwiftUI
import PackItKit
import UniformTypeIdentifiers

struct TemplateExportSheet: View {
    @Environment(PackItStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let template: PackingTemplate

    @State private var exportFormat: TemplateExportFormat = .packittemplate
    @State private var showFileSaver = false
    @State private var exportData: Data?
    @State private var exportError: String?

    enum TemplateExportFormat: String, CaseIterable {
        case packittemplate = "PackIt Template (.packittemplate)"
        case html = "HTML"
        case csv = "CSV"

        var utType: UTType {
            switch self {
            case .packittemplate: return UTType(exportedAs: "com.msjurset.packit.template")
            case .html: return .html
            case .csv: return .commaSeparatedText
            }
        }

        var fileExtension: String {
            switch self {
            case .packittemplate: return "packittemplate"
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
                        ForEach(TemplateExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Preview") {
                    Text("Template: \(template.name)")
                    Text("Items: \(template.itemCount)")
                    if template.prepTaskCount > 0 { Text("Prep Tasks: \(template.prepTaskCount)") }
                    if !template.procedures.isEmpty { Text("Procedures: \(template.procedures.count)") }
                    if !template.referenceLinks.isEmpty { Text("Links: \(template.referenceLinks.count)") }
                    if !template.contextTags.isEmpty {
                        Text("Tags: \(template.contextTags.joined(separator: ", "))")
                    }
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
        .frame(width: 450, height: 380)
        .fileExporter(
            isPresented: $showFileSaver,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat.utType,
            defaultFilename: "\(template.name).\(exportFormat.fileExtension)"
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
                case .packittemplate:
                    exportData = try await store.exportTemplate(template)
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
        let name = esc(template.name)
        var html = """
        <!DOCTYPE html>
        <html><head><meta charset="UTF-8">
        <title>\(name) - Packing Template</title>
        <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, Helvetica Neue, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 24px; color: #2c3e50; line-height: 1.5; }
        h1 { color: #1a7a7a; border-bottom: 3px solid #1a7a7a; padding-bottom: 10px; font-size: 28px; }
        h2 { color: #1a7a7a; margin-top: 28px; font-size: 18px; border-bottom: 1px solid #e0e0e0; padding-bottom: 6px; }
        .meta { color: #7f8c8d; font-size: 14px; margin-bottom: 24px; }
        .tag { display: inline-block; background: #e8f5f5; color: #1a7a7a; padding: 2px 10px; border-radius: 12px; font-size: 12px; margin-right: 4px; }
        .item { padding: 8px 12px; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; }
        .item:hover { background: #f8fafa; }
        .checkbox { width: 18px; height: 18px; margin-right: 10px; accent-color: #1a7a7a; }
        .priority-high { color: #e67e22; font-weight: 500; }
        .priority-critical { color: #e74c3c; font-weight: 600; }
        .notes { font-size: 12px; color: #95a5a6; margin-left: 8px; }
        @media print { body { margin: 20px; font-size: 12px; } .item:hover { background: none; } }
        @media (prefers-color-scheme: dark) {
          body { background: #1a1a2e; color: #e0e0e0; }
          h1, h2 { color: #33b3b3; border-color: #33b3b3; }
          .meta { color: #8899aa; }
          .tag { background: #1a3a3a; color: #33b3b3; }
          .item { border-color: #2a2a3e; }
          .item:hover { background: #222238; }
          .notes { color: #778899; }
        }
        </style></head><body>
        <h1>\(name)</h1>
        <div class="meta">\(template.itemCount) items across \(template.categories.count) categories
        """

        if !template.contextTags.isEmpty {
            html += "<br>"
            for tag in template.contextTags {
                html += "<span class=\"tag\">\(esc(tag))</span>"
            }
        }
        html += "</div>"

        let grouped = Dictionary(grouping: template.items, by: { $0.category ?? "Uncategorized" })
        for category in grouped.keys.sorted() {
            html += "<h2>\(esc(category))</h2>"
            for item in grouped[category] ?? [] {
                let qty = item.quantity > 1 ? " ×\(item.quantity)" : ""
                var extra = ""
                if let owner = item.owner, !owner.isEmpty { extra += " <span class=\"tag\" style=\"background:#e8e0f0;color:#6b4c9a\">\(esc(owner))</span>" }
                if let notes = item.notes, !notes.isEmpty { extra += " <span class=\"notes\">\(esc(notes))</span>" }
                html += "<div class=\"item\"><input type=\"checkbox\" class=\"checkbox\"><span>\(esc(item.name))\(qty)</span>\(extra)</div>"
            }
        }

        if template.prepTaskCount > 0 {
            html += "<h2>Prep Tasks</h2>"
            let prepGrouped = Dictionary(grouping: template.prepTasks, by: \.timing)
            for timing in PrepTaskTiming.allCases {
                guard let tasks = prepGrouped[timing], !tasks.isEmpty else { continue }
                html += "<h3>\(timing.label)</h3>"
                for task in tasks {
                    var extra = ""
                    if let cat = task.category { extra += " <span class=\"tag\">\(esc(cat))</span>" }
                    html += "<div class=\"item\"><input type=\"checkbox\" class=\"checkbox\"><span>\(esc(task.name))</span>\(extra)</div>"
                }
            }
        }

        for proc in template.procedures {
            html += "<h2>\(esc(proc.name)) <small style=\"color:#999\">\(proc.phase.label)</small></h2>"
            for (i, step) in proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
                var notes = ""
                if let n = step.notes, !n.isEmpty { notes = " <span class=\"notes\">\(esc(n))</span>" }
                html += "<div class=\"item\" style=\"padding-left:24px\"><span style=\"color:#999;font-size:12px\">\(i+1).</span> <span>\(esc(step.text))</span>\(notes)</div>"
            }
        }

        if !template.referenceLinks.isEmpty {
            html += "<h2>Reference Links</h2><ul>"
            for link in template.referenceLinks {
                html += "<li><a href=\"\(esc(link.url))\" style=\"color:#1a7a7a\">\(esc(link.label))</a></li>"
            }
            html += "</ul>"
        }

        html += "</body></html>"
        return html
    }

    private func csvEsc(_ text: String) -> String {
        text.replacingOccurrences(of: "\"", with: "\"\"")
    }

    private func generateCSV() -> String {
        var csv = "ITEMS\n"
        csv += "Category,Item,Owner,Quantity,Priority,Notes,Tags\n"
        for item in template.items {
            csv += "\"\(csvEsc(item.category ?? ""))\",\"\(csvEsc(item.name))\",\"\(csvEsc(item.owner ?? ""))\",\"\(item.quantity)\",\"\(item.priority.label)\",\"\(csvEsc(item.notes ?? ""))\",\"\(item.contextTags.joined(separator: "; "))\"\n"
        }

        if template.prepTaskCount > 0 {
            csv += "\nPREP TASKS\n"
            csv += "Timing,Task,Category,Tags\n"
            for task in template.prepTasks {
                csv += "\"\(task.timing.label)\",\"\(csvEsc(task.name))\",\"\(csvEsc(task.category ?? ""))\",\"\(task.contextTags.joined(separator: "; "))\"\n"
            }
        }

        for proc in template.procedures {
            csv += "\nPROCEDURE: \(proc.name) (\(proc.phase.label))\n"
            csv += "Step,Description,Notes\n"
            for (i, step) in proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
                csv += "\"\(i+1)\",\"\(csvEsc(step.text))\",\"\(csvEsc(step.notes ?? ""))\"\n"
            }
        }

        if !template.referenceLinks.isEmpty {
            csv += "\nREFERENCE LINKS\n"
            csv += "Label,URL\n"
            for link in template.referenceLinks {
                csv += "\"\(csvEsc(link.label))\",\"\(csvEsc(link.url))\"\n"
            }
        }

        return csv
    }
}
