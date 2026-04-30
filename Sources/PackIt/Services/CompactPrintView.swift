import AppKit
import PackItKit
import CoreGraphics

struct CompactMeasurements {
    let margin: CGFloat
    let headerHeight: CGFloat
    let boxPadding: CGFloat
    let boxSpacing: CGFloat
    let boxHeaderHeight: CGFloat
    let itemHeight: CGFloat
    let checkSize: CGFloat
    let itemFontSize: CGFloat
    let catFontSize: CGFloat
    let minBoxWidth: CGFloat
    let dotRadius: CGFloat
    let titleFontSize: CGFloat
    let itemTextPadding: CGFloat

    static let compact = CompactMeasurements(
        margin: 30, headerHeight: 50, boxPadding: 6, boxSpacing: 6,
        boxHeaderHeight: 14, itemHeight: 11, checkSize: 5.5,
        itemFontSize: 7, catFontSize: 6.5, minBoxWidth: 140,
        dotRadius: 1.5, titleFontSize: 16, itemTextPadding: 4
    )

    static let dense = CompactMeasurements(
        margin: 22, headerHeight: 40, boxPadding: 3, boxSpacing: 3,
        boxHeaderHeight: 10, itemHeight: 8.5, checkSize: 4,
        itemFontSize: 5.5, catFontSize: 5.5, minBoxWidth: 105,
        dotRadius: 1, titleFontSize: 12, itemTextPadding: 1
    )
}

class CompactPrintView: NSView {
    let trip: TripInstance
    let printConfig: AppConfig
    let m: CompactMeasurements
    private var pageRects: [CGRect] = []
    private var printableWidth: CGFloat = 0
    private var printableHeight: CGFloat = 0

    private var itemFont: NSFont { NSFont.systemFont(ofSize: m.itemFontSize, weight: .regular) }
    private var catFont: NSFont { NSFont.systemFont(ofSize: m.catFontSize, weight: .bold) }

    private struct CategoryBox {
        let name: String
        let items: [TripItem]
        let prepTasks: [PrepTask]
        let packed: Int
        var width: CGFloat = 0
        var height: CGFloat = 0
        var procedureSteps: [ProcedureStep] = []
        var textLines: [String] = []

        var totalRows: Int { items.count + prepTasks.count + procedureSteps.count + textLines.count }
    }

    private struct Section {
        let title: String?
        let boxes: [CategoryBox]
    }

    init(trip: TripInstance, printConfig: AppConfig, measurements: CompactMeasurements = .compact) {
        self.trip = trip
        self.printConfig = printConfig
        self.m = measurements
        super.init(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build Sections

    private func buildSections() -> [Section] {
        let colCount = max(1, Int(printableWidth / (m.minBoxWidth + m.boxSpacing)))
        let boxWidth = (printableWidth - m.boxSpacing * CGFloat(colCount - 1)) / CGFloat(colCount)
        var sections: [Section] = []

        // 1. Packing items
        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        let itemBoxes = grouped.keys.sorted().map { category in
            let items = grouped[category] ?? []
            let packed = items.filter(\.isPacked).count
            let h = m.boxHeaderHeight + CGFloat(items.count) * m.itemHeight + m.boxPadding * 2
            return CategoryBox(name: category, items: items, prepTasks: [], packed: packed, width: boxWidth, height: h)
        }
        if !itemBoxes.isEmpty { sections.append(Section(title: nil, boxes: itemBoxes)) }

        // 2. Prep tasks
        if !trip.prepTasks.isEmpty {
            let prepGrouped = Dictionary(grouping: trip.prepTasks, by: \.timing)
            let prepBoxes = PrepTaskTiming.allCases.compactMap { timing -> CategoryBox? in
                guard let tasks = prepGrouped[timing], !tasks.isEmpty else { return nil }
                let complete = tasks.filter(\.isComplete).count
                let h = m.boxHeaderHeight + CGFloat(tasks.count) * m.itemHeight + m.boxPadding * 2
                return CategoryBox(name: "✓ " + timing.label, items: [], prepTasks: tasks, packed: complete, width: boxWidth, height: h)
            }
            if !prepBoxes.isEmpty { sections.append(Section(title: "Prep Tasks", boxes: prepBoxes)) }
        }

        // 3. Procedures
        if !trip.procedures.isEmpty {
            let procBoxes = trip.procedures.sorted(by: { $0.phase < $1.phase }).map { proc in
                let steps = proc.steps.sorted(by: { $0.sortOrder < $1.sortOrder })
                let h = m.boxHeaderHeight + CGFloat(steps.count) * m.itemHeight + m.boxPadding * 2
                return CategoryBox(name: proc.name, items: [], prepTasks: [], packed: proc.completedCount, width: boxWidth, height: h, procedureSteps: steps)
            }
            sections.append(Section(title: "Procedures", boxes: procBoxes))
        }

        // 4. Meal plan
        if let plan = trip.mealPlan, !plan.days.isEmpty {
            var mealBoxes: [CategoryBox] = []
            for day in plan.days {
                var lines: [String] = []
                for type in MealType.allCases {
                    let slot = day.slot(for: type)
                    if !slot.isEmpty { lines.append(type.label + ": " + slot.display) }
                }
                if !lines.isEmpty {
                    let h = m.boxHeaderHeight + CGFloat(lines.count) * m.itemHeight + m.boxPadding * 2
                    mealBoxes.append(CategoryBox(name: day.dayLabel + " " + day.dateLabel, items: [], prepTasks: [], packed: 0, width: boxWidth, height: h, textLines: lines))
                }
            }
            if !mealBoxes.isEmpty { sections.append(Section(title: "Meal Plan", boxes: mealBoxes)) }
        }

        // 5. Activities + Links (grouped)
        var miscLines: [String] = []
        for activity in trip.activities.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            miscLines.append("• " + activity.text)
        }
        for link in trip.referenceLinks {
            miscLines.append("🔗 " + link.label + " — " + link.url)
        }
        if !miscLines.isEmpty {
            let h = m.boxHeaderHeight + CGFloat(miscLines.count) * m.itemHeight + m.boxPadding * 2
            let box = CategoryBox(name: "Activities & Links", items: [], prepTasks: [], packed: 0, width: boxWidth, height: h, textLines: miscLines)
            sections.append(Section(title: nil, boxes: [box]))
        }

        return sections
    }

    // MARK: - Pagination

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        guard let printInfo = NSPrintOperation.current?.printInfo else { return false }
        let paperSize = printInfo.paperSize
        printableWidth = paperSize.width - m.margin * 2
        printableHeight = paperSize.height - m.margin * 2
        pageRects = calculatePages()
        range.pointee = NSRange(location: 1, length: pageRects.count)
        self.frame = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height * CGFloat(pageRects.count))
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        guard page > 0 && page <= pageRects.count else { return .zero }
        return pageRects[page - 1]
    }

    private func calculatePages() -> [CGRect] {
        guard let printInfo = NSPrintOperation.current?.printInfo else { return [] }
        let paperSize = printInfo.paperSize
        let sections = buildSections()
        let colCount = max(1, Int(printableWidth / (m.minBoxWidth + m.boxSpacing)))
        let usableHeight = printableHeight - m.headerHeight
        var totalPages = 0

        for section in sections {
            totalPages += 1 // each section starts a new page
            var colHeights = [CGFloat](repeating: 0, count: colCount)
            for box in section.boxes {
                let minCol = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
                if colHeights[minCol] + box.height > usableHeight {
                    totalPages += 1
                    colHeights = [CGFloat](repeating: 0, count: colCount)
                }
                colHeights[minCol] += box.height + m.boxSpacing
            }
        }

        return (0..<max(1, totalPages)).map { i in
            CGRect(x: 0, y: CGFloat(i) * paperSize.height, width: paperSize.width, height: paperSize.height)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let printInfo = NSPrintOperation.current?.printInfo else { return }

        let paperSize = printInfo.paperSize
        let currentPage = Int(dirtyRect.minY / paperSize.height)

        context.setFillColor(CGColor.white)
        context.fill(dirtyRect)
        WatermarkRenderer.draw(config: printConfig, in: dirtyRect, context: context)

        let x = m.margin
        let topY = dirtyRect.maxY - m.margin

        var contentStartY: CGFloat
        if currentPage == 0 {
            contentStartY = drawHeader(at: CGPoint(x: x, y: topY), width: printableWidth, context: context)
        } else {
            contentStartY = drawContinuationHeader(at: CGPoint(x: x, y: topY), page: currentPage + 1, context: context)
        }

        let sections = buildSections()
        let colCount = max(1, Int(printableWidth / (m.minBoxWidth + m.boxSpacing)))
        let boxWidth = (printableWidth - m.boxSpacing * CGFloat(colCount - 1)) / CGFloat(colCount)
        let usableHeight = contentStartY - dirtyRect.minY - m.margin

        var pageIdx = 0

        for (sIdx, section) in sections.enumerated() {
            if sIdx > 0 { // each section after the first starts a new page
                pageIdx += 1
            }
            var colHeights = [CGFloat](repeating: 0, count: colCount)

            for box in section.boxes {
                let minCol = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
                if colHeights[minCol] + box.height > usableHeight {
                    pageIdx += 1
                    colHeights = [CGFloat](repeating: 0, count: colCount)
                }
                let colIdx = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset

                if pageIdx == currentPage {
                    let bx = x + CGFloat(colIdx) * (boxWidth + m.boxSpacing)
                    let by = contentStartY - colHeights[colIdx]
                    drawCategoryBox(box, at: CGPoint(x: bx, y: by), width: boxWidth, context: context)
                }
                colHeights[colIdx] += box.height + m.boxSpacing
            }
        }
    }

    // MARK: - Category Box

    private func drawCategoryBox(_ box: CategoryBox, at point: CGPoint, width: CGFloat, context: CGContext) {
        let boxRect = CGRect(x: point.x, y: point.y - box.height, width: width, height: box.height)

        context.setFillColor(CGColor(gray: 0.97, alpha: 1))
        let path = CGPath(roundedRect: boxRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        context.addPath(path)
        context.fillPath()

        context.setStrokeColor(CGColor(gray: 0.82, alpha: 1))
        context.setLineWidth(0.4)
        context.addPath(path)
        context.strokePath()

        let headerY = point.y - m.boxPadding
        let catAttrs: [NSAttributedString.Key: Any] = [.font: catFont, .foregroundColor: NSColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1)]
        NSAttributedString(string: box.name.uppercased(), attributes: catAttrs)
            .draw(at: NSPoint(x: point.x + m.boxPadding, y: headerY - m.catFontSize - 1.5))

        if box.totalRows > 0 {
            let countAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: m.catFontSize - 0.5, weight: .regular), .foregroundColor: NSColor.gray]
            let countAS = NSAttributedString(string: "\(box.packed)/\(box.totalRows)", attributes: countAttrs)
            countAS.draw(at: NSPoint(x: point.x + width - m.boxPadding - countAS.size().width, y: headerY - m.catFontSize - 1))
        }

        let lineY = headerY - m.boxHeaderHeight + 1
        context.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        context.setLineWidth(0.3)
        context.move(to: CGPoint(x: point.x + m.boxPadding, y: lineY))
        context.addLine(to: CGPoint(x: point.x + width - m.boxPadding, y: lineY))
        context.strokePath()

        var itemY = lineY - 1
        for item in box.items {
            drawCompactItem(item, at: CGPoint(x: point.x + m.boxPadding, y: itemY), width: width - m.boxPadding * 2, context: context)
            itemY -= m.itemHeight
        }
        for task in box.prepTasks {
            drawCompactPrepTask(task, at: CGPoint(x: point.x + m.boxPadding, y: itemY), width: width - m.boxPadding * 2, context: context)
            itemY -= m.itemHeight
        }
        for step in box.procedureSteps {
            drawCompactPrepTask(PrepTask(name: step.text, isComplete: step.isComplete), at: CGPoint(x: point.x + m.boxPadding, y: itemY), width: width - m.boxPadding * 2, context: context)
            itemY -= m.itemHeight
        }
        for line in box.textLines {
            let attrs: [NSAttributedString.Key: Any] = [.font: itemFont, .foregroundColor: NSColor.black]
            NSAttributedString(string: line, attributes: attrs)
                .draw(in: CGRect(x: point.x + m.boxPadding, y: itemY - m.itemHeight, width: width - m.boxPadding * 2 - m.itemTextPadding, height: m.itemFontSize + 3))
            itemY -= m.itemHeight
        }
    }

    // MARK: - Compact Item

    private func drawCompactItem(_ item: TripItem, at point: CGPoint, width: CGFloat, context: CGContext) {
        let y = point.y
        let checkRect = CGRect(x: point.x, y: y - m.checkSize - 0.5, width: m.checkSize, height: m.checkSize)
        context.setLineWidth(0.4)
        context.setStrokeColor(CGColor(gray: 0.55, alpha: 1))
        context.strokeEllipse(in: checkRect)

        if item.isPacked {
            context.setStrokeColor(CGColor(red: 0.2, green: 0.65, blue: 0.35, alpha: 1))
            context.setLineWidth(0.7)
            context.move(to: CGPoint(x: checkRect.minX + 1, y: checkRect.midY))
            context.addLine(to: CGPoint(x: checkRect.midX, y: checkRect.minY + 0.8))
            context.addLine(to: CGPoint(x: checkRect.maxX - 0.8, y: checkRect.maxY - 0.8))
            context.strokePath()
        }

        let dotX = point.x + m.checkSize + 3
        let dotY = y - m.checkSize / 2 - 0.5
        let dotColors: [Priority: CGColor] = [
            .low: CGColor(gray: 0.75, alpha: 1), .medium: CGColor(red: 0.3, green: 0.5, blue: 0.85, alpha: 1),
            .high: CGColor(red: 0.9, green: 0.6, blue: 0.15, alpha: 1), .critical: CGColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1),
        ]
        context.setFillColor(dotColors[item.priority] ?? CGColor(gray: 0.5, alpha: 1))
        context.fillEllipse(in: CGRect(x: dotX - m.dotRadius, y: dotY - m.dotRadius, width: m.dotRadius * 2, height: m.dotRadius * 2))

        let textX = dotX + m.dotRadius + 2
        let textColor: NSColor = item.isPacked ? .gray : .black
        let textAttrs: [NSAttributedString.Key: Any] = [.font: itemFont, .foregroundColor: textColor, .strikethroughStyle: item.isPacked ? NSUnderlineStyle.single.rawValue : 0]
        let maxTextWidth = width - (textX - point.x) - m.itemTextPadding
        let quantitySuffix = item.quantity > 1 ? " ×\(item.quantity)" : ""
        NSAttributedString(string: item.name + quantitySuffix, attributes: textAttrs)
            .draw(in: CGRect(x: textX, y: y - m.checkSize - 1.5, width: maxTextWidth, height: m.itemFontSize + 3))
    }

    // MARK: - Compact Prep Task

    private func drawCompactPrepTask(_ task: PrepTask, at point: CGPoint, width: CGFloat, context: CGContext) {
        let y = point.y
        let checkRect = CGRect(x: point.x, y: y - m.checkSize - 0.5, width: m.checkSize, height: m.checkSize)
        context.setLineWidth(0.4)
        context.setStrokeColor(CGColor(gray: 0.55, alpha: 1))
        let path = CGPath(roundedRect: checkRect, cornerWidth: 1, cornerHeight: 1, transform: nil)
        context.addPath(path)
        context.strokePath()

        if task.isComplete {
            context.setStrokeColor(CGColor(red: 0.2, green: 0.65, blue: 0.35, alpha: 1))
            context.setLineWidth(0.7)
            context.move(to: CGPoint(x: checkRect.minX + 1, y: checkRect.midY))
            context.addLine(to: CGPoint(x: checkRect.midX, y: checkRect.minY + 0.8))
            context.addLine(to: CGPoint(x: checkRect.maxX - 0.8, y: checkRect.maxY - 0.8))
            context.strokePath()
        }

        let textX = point.x + m.checkSize + 3
        let textColor: NSColor = task.isComplete ? .gray : .black
        let textAttrs: [NSAttributedString.Key: Any] = [.font: itemFont, .foregroundColor: textColor, .strikethroughStyle: task.isComplete ? NSUnderlineStyle.single.rawValue : 0]
        let maxTextWidth = width - (textX - point.x) - m.itemTextPadding
        NSAttributedString(string: task.name, attributes: textAttrs)
            .draw(in: CGRect(x: textX, y: y - m.checkSize - 1.5, width: maxTextWidth, height: m.itemFontSize + 3))
    }

    // MARK: - Headers

    private func drawHeader(at point: CGPoint, width: CGFloat, context: CGContext) -> CGFloat {
        var y = point.y
        let titleFont = NSFont.systemFont(ofSize: m.titleFontSize, weight: .bold)
        NSAttributedString(string: trip.name, attributes: [.font: titleFont, .foregroundColor: NSColor.black])
            .draw(at: NSPoint(x: point.x, y: y - m.titleFontSize - 2))

        let progressSize = max(m.titleFontSize - 7, 7)
        let progressStr = "\(trip.packedCount)/\(trip.totalItems) packed"
        let progressAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: progressSize, weight: .semibold), .foregroundColor: NSColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 1)]
        let progressAS = NSAttributedString(string: progressStr, attributes: progressAttrs)
        progressAS.draw(at: NSPoint(x: point.x + width - progressAS.size().width, y: y - m.titleFontSize))
        y -= m.titleFontSize + 6

        let subSize = max(m.titleFontSize - 8, 6)
        let subFont = NSFont.systemFont(ofSize: subSize, weight: .regular)
        var dateStr = trip.departureDate.formatted(date: .abbreviated, time: .omitted)
        if let ret = trip.returnDate { dateStr += "  —  \(ret.formatted(date: .abbreviated, time: .omitted))" }
        NSAttributedString(string: dateStr, attributes: [.font: subFont, .foregroundColor: NSColor.darkGray])
            .draw(at: NSPoint(x: point.x, y: y - subSize - 2))
        y -= subSize + 6

        context.setStrokeColor(CGColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 0.3))
        context.setLineWidth(0.8)
        context.move(to: CGPoint(x: point.x, y: y))
        context.addLine(to: CGPoint(x: point.x + width, y: y))
        context.strokePath()
        y -= 4
        return y
    }

    private func drawContinuationHeader(at point: CGPoint, page: Int, context: CGContext) -> CGFloat {
        let fontSize = max(m.titleFontSize - 8, 6)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        NSAttributedString(string: "\(trip.name) — Page \(page)", attributes: [.font: font, .foregroundColor: NSColor.gray])
            .draw(at: NSPoint(x: point.x, y: point.y - fontSize - 2))
        context.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        context.setLineWidth(0.3)
        context.move(to: CGPoint(x: point.x, y: point.y - fontSize - 4))
        context.addLine(to: CGPoint(x: point.x + printableWidth, y: point.y - fontSize - 4))
        context.strokePath()
        return point.y - fontSize - 10
    }
}
