import AppKit
import CoreGraphics

class PackingListPrintView: NSView {
    let trip: TripInstance
    let printConfig: AppConfig
    private var pageRects: [CGRect] = []
    private let margin: CGFloat = 36  // 0.5 inch
    private let itemHeight: CGFloat = 16
    private let itemWithNoteHeight: CGFloat = 26
    private let categoryHeaderHeight: CGFloat = 22
    private let categorySpacing: CGFloat = 10
    private let headerHeight: CGFloat = 70
    private let columnGap: CGFloat = 12
    private var printableWidth: CGFloat = 0
    private var printableHeight: CGFloat = 0
    private var columnCount: Int = 3

    init(trip: TripInstance, printConfig: AppConfig) {
        self.trip = trip
        self.printConfig = printConfig
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Pagination

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        guard let printInfo = NSPrintOperation.current?.printInfo else { return false }
        let paperSize = printInfo.paperSize
        printableWidth = paperSize.width - margin * 2
        printableHeight = paperSize.height - margin * 2

        // Determine column count based on page width
        if printableWidth > 650 { columnCount = 3 }
        else if printableWidth > 420 { columnCount = 2 }
        else { columnCount = 1 }

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

        // Build flat list of render blocks to flow into columns
        let blocks = buildBlocks()
        let usableHeight = printableHeight - headerHeight
        let colWidth = (printableWidth - columnGap * CGFloat(columnCount - 1)) / CGFloat(columnCount)

        // Flow blocks into columns across pages
        var pageCount = 1
        var colIndex = 0
        var colY: CGFloat = 0

        for block in blocks {
            let blockHeight = block.height
            if colY + blockHeight > usableHeight {
                colIndex += 1
                colY = 0
                if colIndex >= columnCount {
                    pageCount += 1
                    colIndex = 0
                }
            }
            colY += blockHeight
        }

        var rects: [CGRect] = []
        for i in 0..<pageCount {
            rects.append(CGRect(x: 0, y: CGFloat(i) * paperSize.height, width: paperSize.width, height: paperSize.height))
        }
        return rects
    }

    // MARK: - Render Blocks

    enum BlockType {
        case categoryHeader(String, Int, Int) // name, packed, total
        case item(TripItem)
    }

    struct RenderBlock {
        let type: BlockType
        let height: CGFloat
    }

    private func buildBlocks() -> [RenderBlock] {
        let grouped = Dictionary(grouping: trip.items, by: { $0.category ?? "Uncategorized" })
        var blocks: [RenderBlock] = []

        for category in grouped.keys.sorted() {
            let items = grouped[category] ?? []
            let packed = items.filter(\.isPacked).count
            blocks.append(RenderBlock(type: .categoryHeader(category, packed, items.count), height: categoryHeaderHeight + categorySpacing))

            for item in items {
                let h = (item.notes != nil && !item.notes!.isEmpty) ? itemWithNoteHeight : itemHeight
                blocks.append(RenderBlock(type: .item(item), height: h))
            }
            blocks.append(RenderBlock(type: .categoryHeader("", 0, 0), height: categorySpacing)) // spacer
        }
        return blocks
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let printInfo = NSPrintOperation.current?.printInfo else { return }

        let paperSize = printInfo.paperSize
        let currentPage = Int(dirtyRect.minY / paperSize.height)

        // White background
        context.setFillColor(CGColor.white)
        context.fill(dirtyRect)

        // Watermark layers
        WatermarkRenderer.draw(config: printConfig, in: dirtyRect, context: context)

        let x = margin
        let topY = dirtyRect.maxY - margin

        // Header
        var contentStartY: CGFloat
        if currentPage == 0 {
            contentStartY = drawHeader(at: CGPoint(x: x, y: topY), width: printableWidth, context: context)
        } else {
            contentStartY = drawContinuationHeader(at: CGPoint(x: x, y: topY), page: currentPage + 1, context: context)
        }

        // Flow blocks into columns for this page
        let blocks = buildBlocks()
        let usableHeight = contentStartY - dirtyRect.minY - margin
        let colWidth = (printableWidth - columnGap * CGFloat(columnCount - 1)) / CGFloat(columnCount)

        var pageIdx = 0
        var colIndex = 0
        var colY: CGFloat = 0

        for block in blocks {
            if block.type is Void { continue } // skip spacer markers check below
            let blockHeight = block.height

            if colY + blockHeight > usableHeight {
                colIndex += 1
                colY = 0
                if colIndex >= columnCount {
                    pageIdx += 1
                    colIndex = 0
                }
            }

            if pageIdx == currentPage {
                let colX = x + CGFloat(colIndex) * (colWidth + columnGap)
                let drawY = contentStartY - colY

                switch block.type {
                case .categoryHeader(let name, let packed, let total):
                    if !name.isEmpty {
                        drawCategoryHeader(name, packed: packed, total: total, at: CGPoint(x: colX, y: drawY), width: colWidth, context: context)
                    }
                case .item(let item):
                    drawItem(item, at: CGPoint(x: colX, y: drawY), width: colWidth, context: context)
                }
            }

            colY += blockHeight
        }
    }

    // MARK: - Header

    private func drawHeader(at point: CGPoint, width: CGFloat, context: CGContext) -> CGFloat {
        var y = point.y

        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: NSColor.black]
        NSAttributedString(string: trip.name, attributes: titleAttrs).draw(at: NSPoint(x: point.x, y: y - 24))

        // Progress on right
        let progressStr = "\(trip.packedCount)/\(trip.totalItems) packed"
        let progressAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold), .foregroundColor: NSColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 1)]
        let progressAS = NSAttributedString(string: progressStr, attributes: progressAttrs)
        progressAS.draw(at: NSPoint(x: point.x + width - progressAS.size().width, y: y - 22))
        y -= 30

        let subFont = NSFont.systemFont(ofSize: 10, weight: .regular)
        let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: NSColor.darkGray]
        var dateStr = trip.departureDate.formatted(date: .long, time: .omitted)
        if let ret = trip.returnDate {
            dateStr += "  —  \(ret.formatted(date: .long, time: .omitted))"
        }
        NSAttributedString(string: dateStr, attributes: subAttrs).draw(at: NSPoint(x: point.x, y: y - 14))
        y -= 20

        // Divider
        context.setStrokeColor(CGColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 0.4))
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: point.x, y: y))
        context.addLine(to: CGPoint(x: point.x + width, y: y))
        context.strokePath()
        y -= 8

        return y
    }

    private func drawContinuationHeader(at point: CGPoint, page: Int, context: CGContext) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 9, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.gray]
        NSAttributedString(string: "\(trip.name) — Page \(page)", attributes: attrs).draw(at: NSPoint(x: point.x, y: point.y - 12))

        context.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: point.x, y: point.y - 16))
        context.addLine(to: CGPoint(x: point.x + printableWidth, y: point.y - 16))
        context.strokePath()

        return point.y - 24
    }

    // MARK: - Category Header

    private func drawCategoryHeader(_ name: String, packed: Int, total: Int, at point: CGPoint, width: CGFloat, context: CGContext) {
        let y = point.y

        let catFont = NSFont.systemFont(ofSize: 9, weight: .bold)
        let catColor = NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1)
        NSAttributedString(string: name.uppercased(), attributes: [.font: catFont, .foregroundColor: catColor]).draw(at: NSPoint(x: point.x + 2, y: y - 12))

        let countAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 8, weight: .regular), .foregroundColor: NSColor.gray]
        let countAS = NSAttributedString(string: "\(packed)/\(total)", attributes: countAttrs)
        countAS.draw(at: NSPoint(x: point.x + width - countAS.size().width - 2, y: y - 11))

        context.setStrokeColor(CGColor(gray: 0.85, alpha: 1))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: point.x, y: y - 16))
        context.addLine(to: CGPoint(x: point.x + width, y: y - 16))
        context.strokePath()
    }

    // MARK: - Item

    private func drawItem(_ item: TripItem, at point: CGPoint, width: CGFloat, context: CGContext) {
        let checkSize: CGFloat = 8
        let y = point.y - 4

        // Checkbox
        let checkRect = CGRect(x: point.x + 4, y: y - checkSize, width: checkSize, height: checkSize)
        context.setLineWidth(0.8)
        context.setStrokeColor(CGColor(gray: 0.5, alpha: 1))
        context.strokeEllipse(in: checkRect)

        if item.isPacked {
            context.setStrokeColor(CGColor(red: 0.2, green: 0.65, blue: 0.35, alpha: 1))
            context.setLineWidth(1.2)
            context.move(to: CGPoint(x: checkRect.minX + 2, y: checkRect.midY))
            context.addLine(to: CGPoint(x: checkRect.midX, y: checkRect.minY + 1.5))
            context.addLine(to: CGPoint(x: checkRect.maxX - 1.5, y: checkRect.maxY - 1.5))
            context.strokePath()
        }

        // Priority dot
        let dotColors: [Priority: CGColor] = [
            .low: CGColor(gray: 0.75, alpha: 1),
            .medium: CGColor(red: 0.3, green: 0.5, blue: 0.85, alpha: 1),
            .high: CGColor(red: 0.9, green: 0.6, blue: 0.15, alpha: 1),
            .critical: CGColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1),
        ]
        let dotR: CGFloat = 2.5
        let dotX = point.x + checkSize + 10
        let dotY = y - checkSize / 2
        context.setFillColor(dotColors[item.priority] ?? CGColor(gray: 0.5, alpha: 1))
        context.fillEllipse(in: CGRect(x: dotX - dotR, y: dotY - dotR, width: dotR * 2, height: dotR * 2))

        // Name
        let textX = dotX + dotR + 5
        let itemFont = NSFont.systemFont(ofSize: 9.5, weight: .regular)
        let textColor: NSColor = item.isPacked ? .gray : .black
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: textColor,
            .strikethroughStyle: item.isPacked ? NSUnderlineStyle.single.rawValue : 0,
        ]
        let maxTextWidth = width - (textX - point.x) - 4
        let textStr = NSAttributedString(string: item.name, attributes: textAttrs)
        textStr.draw(in: CGRect(x: textX, y: y - checkSize - 1, width: maxTextWidth, height: 14))

        // Notes
        if let notes = item.notes, !notes.isEmpty {
            let noteFont = NSFont.systemFont(ofSize: 7.5, weight: .regular)
            let noteAttrs: [NSAttributedString.Key: Any] = [.font: noteFont, .foregroundColor: NSColor.gray]
            NSAttributedString(string: notes, attributes: noteAttrs).draw(in: CGRect(x: textX, y: y - checkSize - 12, width: maxTextWidth, height: 10))
        }
    }
}

struct PrintService {
    @MainActor
    static func print(trip: TripInstance, config: AppConfig) {
        let printView = PackingListPrintView(trip: trip, printConfig: config)

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.dictionary()[NSPrintInfo.AttributeKey("NSPrintHeaderAndFooter")] = false

        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }
}
