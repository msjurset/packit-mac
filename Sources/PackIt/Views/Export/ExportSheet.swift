import SwiftUI
import PackItKit
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
                    if !trip.prepTasks.isEmpty { Text("Prep Tasks: \(trip.prepTasks.count)") }
                    if !trip.procedures.isEmpty { Text("Procedures: \(trip.procedures.count)") }
                    if trip.mealPlan != nil { Text("Meal Plan: \(trip.mealPlan!.days.count) days") }
                    if !trip.activities.isEmpty { Text("Activities: \(trip.activities.count)") }
                    if !trip.referenceLinks.isEmpty { Text("Links: \(trip.referenceLinks.count)") }
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
        <title>\(name)</title>
        <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, Helvetica Neue, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 24px; color: #2c3e50; line-height: 1.5; }
        h1 { color: #1a7a7a; border-bottom: 3px solid #1a7a7a; padding-bottom: 10px; font-size: 28px; }
        h2 { color: #1a7a7a; margin-top: 28px; font-size: 18px; border-bottom: 1px solid #e0e0e0; padding-bottom: 6px; }
        h3 { color: #555; margin-top: 16px; font-size: 14px; }
        .meta { color: #7f8c8d; font-size: 14px; margin-bottom: 24px; }
        .item { padding: 6px 12px; border-bottom: 1px solid #f0f0f0; display: flex; align-items: center; gap: 8px; }
        .packed { color: #95a5a6; } .packed span { text-decoration: line-through; }
        .checkbox { width: 16px; height: 16px; accent-color: #1a7a7a; flex-shrink: 0; }
        .owner { background: #e8e0f0; color: #6b4c9a; padding: 1px 8px; border-radius: 10px; font-size: 11px; }
        .tag { display: inline-block; background: #e8f5f5; color: #1a7a7a; padding: 1px 8px; border-radius: 10px; font-size: 11px; }
        .notes-text { font-size: 12px; color: #95a5a6; }
        .section-notes { background: #f7f9f9; padding: 12px 16px; border-radius: 8px; border: 1px solid #e8eded; white-space: pre-wrap; margin: 8px 0; font-size: 13px; }
        .step { padding: 4px 12px 4px 24px; }
        .step-num { color: #999; font-size: 12px; margin-right: 6px; }
        .meal-table { width: 100%; border-collapse: collapse; margin: 8px 0; }
        .meal-table th { text-align: left; padding: 6px 10px; background: #f0f8f8; color: #1a7a7a; font-size: 12px; border-bottom: 2px solid #d0e8e8; }
        .meal-table td { padding: 6px 10px; border-bottom: 1px solid #f0f0f0; font-size: 13px; vertical-align: top; }
        .link { color: #1a7a7a; }
        .progress { font-size: 14px; color: #1a7a7a; font-weight: 600; }
        @media print { body { margin: 20px; font-size: 12px; } h2 { page-break-before: auto; } }
        @media (prefers-color-scheme: dark) {
          body { background: #1a1a2e; color: #e0e0e0; }
          h1, h2 { color: #33b3b3; border-color: #33b3b3; }
          .meta { color: #8899aa; } .item { border-color: #2a2a3e; }
          .packed { color: #667788; } .section-notes { background: #222238; border-color: #333348; }
          .owner { background: #2a2040; color: #b09ad0; } .tag { background: #1a3a3a; color: #33b3b3; }
          .meal-table th { background: #1a3a3a; } .meal-table td { border-color: #2a2a3e; }
          .link { color: #33b3b3; } .progress { color: #33b3b3; }
        }
        </style></head><body>
        <h1>\(name)</h1>
        <div class="meta">
        """
        if let dest = trip.destination { html += "📍 \(esc(dest.displayName))<br>" }
        html += "Departure: \(trip.departureDate.formatted(date: .long, time: .omitted))"
        if let ret = trip.returnDate { html += " &middot; Return: \(ret.formatted(date: .long, time: .omitted))" }
        html += " &middot; <span class=\"progress\">\(trip.packedCount)/\(trip.totalItems) packed</span></div>"

        // Packing items
        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        for category in grouped.keys.sorted() {
            html += "<h2>\(esc(category))</h2>"
            for item in grouped[category] ?? [] {
                let cls = item.isPacked ? "item packed" : "item"
                let check = item.isPacked ? "checked" : ""
                let qty = item.quantity > 1 ? " ×\(item.quantity)" : ""
                var extra = ""
                if let owner = item.owner, !owner.isEmpty { extra += " <span class=\"owner\">\(esc(owner))</span>" }
                if let notes = item.notes, !notes.isEmpty { extra += " <span class=\"notes-text\">\(esc(notes))</span>" }
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)><span>\(esc(item.name))\(qty)</span>\(extra)</div>"
            }
        }

        // Prep tasks
        if !trip.prepTasks.isEmpty {
            html += "<h2>Prep Tasks</h2>"
            let prepGrouped = Dictionary(grouping: trip.prepTasks, by: \.timing)
            for timing in PrepTaskTiming.allCases {
                guard let tasks = prepGrouped[timing], !tasks.isEmpty else { continue }
                html += "<h3>\(timing.label) — \(tasks.first?.dueDate.formatted(date: .abbreviated, time: .omitted) ?? "")</h3>"
                for task in tasks {
                    let check = task.isComplete ? "checked" : ""
                    let cls = task.isComplete ? "item packed" : "item"
                    var extra = ""
                    if let cat = task.category { extra += " <span class=\"tag\">\(esc(cat))</span>" }
                    html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)><span>\(esc(task.name))</span>\(extra)</div>"
                }
            }
        }

        // Procedures
        for proc in trip.procedures.sorted(by: { $0.phase < $1.phase }) {
            html += "<h2>\(esc(proc.name)) <small style=\"color:#999\">\(proc.phase.label)</small></h2>"
            for (i, step) in proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
                let check = step.isComplete ? "checked" : ""
                let cls = step.isComplete ? "step packed" : "step"
                var notes = ""
                if let n = step.notes, !n.isEmpty { notes = " <span class=\"notes-text\">\(esc(n))</span>" }
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)><span class=\"step-num\">\(i+1).</span> <span>\(esc(step.text))</span>\(notes)</div>"
            }
        }

        // Meal plan
        if let plan = trip.mealPlan, !plan.days.isEmpty {
            html += "<h2>Meal Plan</h2>"
            if !plan.prepNotes.isEmpty {
                html += "<div class=\"section-notes\">🍳 \(esc(plan.prepNotes))</div>"
            }
            html += "<table class=\"meal-table\"><tr><th>Day</th><th>Breakfast</th><th>Lunch</th><th>Dinner</th><th>Snacks</th><th>Beverages</th></tr>"
            for day in plan.days {
                html += "<tr><td><strong>\(day.dayLabel)</strong><br>\(day.dateLabel)</td>"
                for type in MealType.allCases {
                    let slot = day.slot(for: type)
                    html += "<td>\(slot.isEmpty ? "—" : esc(slot.display))</td>"
                }
                html += "</tr>"
            }
            html += "</table>"
        }

        // Activities
        if !trip.activities.isEmpty {
            html += "<h2>Activities</h2><ul>"
            for activity in trip.activities.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                html += "<li>\(esc(activity.text))</li>"
            }
            html += "</ul>"
        }

        // Reference links
        if !trip.referenceLinks.isEmpty {
            html += "<h2>Reference Links</h2><ul>"
            for link in trip.referenceLinks {
                html += "<li><a class=\"link\" href=\"\(esc(link.url))\">\(esc(link.label))</a></li>"
            }
            html += "</ul>"
        }

        // TODOs
        if !trip.todos.isEmpty {
            html += "<h2>TODOs</h2>"
            for todo in trip.todos {
                let check = todo.isComplete ? "checked" : ""
                let cls = todo.isComplete ? "item packed" : "item"
                html += "<div class=\"\(cls)\"><input type=\"checkbox\" class=\"checkbox\" \(check)><span>\(esc(todo.text))</span></div>"
            }
        }

        // Notes
        if !trip.scratchNotes.isEmpty {
            html += "<h2>Notes</h2><div class=\"section-notes\">\(esc(trip.scratchNotes))</div>"
        }

        html += "</body></html>"
        return html
    }

    private func csvEsc(_ text: String) -> String {
        text.replacingOccurrences(of: "\"", with: "\"\"")
    }

    private func generateCSV() -> String {
        var csv = ""

        // Packing Items
        csv += "PACKING ITEMS\n"
        csv += "Category,Item,Owner,Quantity,Priority,Packed,Notes\n"
        for item in trip.items {
            csv += "\"\(csvEsc(item.category ?? ""))\",\"\(csvEsc(item.name))\",\"\(csvEsc(item.owner ?? ""))\",\"\(item.quantity)\",\"\(item.priority.label)\",\"\(item.isPacked ? "Yes" : "No")\",\"\(csvEsc(item.notes ?? ""))\"\n"
        }

        // Prep Tasks
        if !trip.prepTasks.isEmpty {
            csv += "\nPREP TASKS\n"
            csv += "Timing,Task,Category,Due Date,Complete\n"
            for task in trip.prepTasks {
                csv += "\"\(task.timing.label)\",\"\(csvEsc(task.name))\",\"\(csvEsc(task.category ?? ""))\",\"\(task.dueDate.formatted(date: .abbreviated, time: .omitted))\",\"\(task.isComplete ? "Yes" : "No")\"\n"
            }
        }

        // Procedures
        for proc in trip.procedures.sorted(by: { $0.phase < $1.phase }) {
            csv += "\nPROCEDURE: \(proc.name) (\(proc.phase.label))\n"
            csv += "Step,Description,Complete,Notes\n"
            for (i, step) in proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
                csv += "\"\(i+1)\",\"\(csvEsc(step.text))\",\"\(step.isComplete ? "Yes" : "No")\",\"\(csvEsc(step.notes ?? ""))\"\n"
            }
        }

        // Meal Plan
        if let plan = trip.mealPlan, !plan.days.isEmpty {
            csv += "\nMEAL PLAN\n"
            csv += "Day,Breakfast,Lunch,Dinner,Snacks,Beverages\n"
            for day in plan.days {
                csv += "\"\(day.dayLabel) \(day.dateLabel)\""
                for type in MealType.allCases {
                    csv += ",\"\(csvEsc(day.slot(for: type).display))\""
                }
                csv += "\n"
            }
        }

        // Activities
        if !trip.activities.isEmpty {
            csv += "\nACTIVITIES\n"
            for activity in trip.activities.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                csv += "\"\(csvEsc(activity.text))\"\n"
            }
        }

        // Reference Links
        if !trip.referenceLinks.isEmpty {
            csv += "\nREFERENCE LINKS\n"
            csv += "Label,URL\n"
            for link in trip.referenceLinks {
                csv += "\"\(csvEsc(link.label))\",\"\(csvEsc(link.url))\"\n"
            }
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
