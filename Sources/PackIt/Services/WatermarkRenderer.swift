import AppKit
import CoreGraphics

struct WatermarkRenderer {

    // MARK: - Main Entry Point

    static func draw(config: AppConfig, in rect: CGRect, context: CGContext) {
        // Layer 1: Full-page art (behind everything)
        if config.enableFullPage && config.fullPageStyle != .none {
            drawFullPage(style: config.fullPageStyle, opacity: config.fullPageOpacity, in: rect, context: context)
        }

        // Layer 2: Repeating pattern
        if config.enablePattern && config.patternStyle != .none {
            drawPattern(style: config.patternStyle, opacity: config.patternOpacity, in: rect, context: context)
        }

        // Layer 3: Border (on top)
        if config.enableBorder && config.borderStyle != .none {
            drawBorder(style: config.borderStyle, opacity: config.borderOpacity, in: rect, context: context)
        }
    }

    // Legacy entry point for backward compatibility
    static func draw(style: PatternStyle, in rect: CGRect, context: CGContext) {
        guard style != .none else { return }
        drawPattern(style: style, opacity: 0.06, in: rect, context: context)
    }

    // MARK: - Pattern Drawing

    private static func drawPattern(style: PatternStyle, opacity: CGFloat, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.setAlpha(opacity)

        switch style {
        case .none: break
        case .palmTrees: drawPalmTrees(in: rect, context: context)
        case .mountains: drawMountains(in: rect, context: context)
        case .compass: drawCompassPattern(in: rect, context: context)
        case .waves: drawWaves(in: rect, context: context)
        case .suitcases: drawSuitcases(in: rect, context: context)
        case .worldDots: drawWorldDots(in: rect, context: context)
        case .tropicalLeaves: drawTropicalLeaves(in: rect, context: context)
        case .anchors: drawAnchors(in: rect, context: context)
        }

        context.restoreGState()
    }

    // MARK: - Full-Page Art

    private static func drawFullPage(style: FullPageStyle, opacity: CGFloat, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.setAlpha(opacity)

        switch style {
        case .none: break
        case .beachScene: drawBeachScene(in: rect, context: context)
        case .mountainLandscape: drawMountainLandscape(in: rect, context: context)
        case .largeCompass: drawLargeCompass(in: rect, context: context)
        case .worldMap: drawWorldMapOutline(in: rect, context: context)
        case .tropicalFrame: drawTropicalFrame(in: rect, context: context)
        case .nauticalChart: drawNauticalChart(in: rect, context: context)
        }

        context.restoreGState()
    }

    // MARK: - Border Drawing

    private static func drawBorder(style: BorderStyle, opacity: CGFloat, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.setAlpha(opacity)

        switch style {
        case .none: break
        case .simpleLine: drawSimpleBorder(in: rect, context: context)
        case .doubleLine: drawDoubleBorder(in: rect, context: context)
        case .rope: drawRopeBorder(in: rect, context: context)
        case .vine: drawVineBorder(in: rect, context: context)
        case .passportStamps: drawPassportBorder(in: rect, context: context)
        case .ticketEdge: drawTicketBorder(in: rect, context: context)
        }

        context.restoreGState()
    }

    // =====================================================================
    // MARK: - Pattern Implementations
    // =====================================================================

    private static func drawPalmTrees(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.1, green: 0.55, blue: 0.4, alpha: 1)
        context.setFillColor(color)
        context.setStrokeColor(color)

        let spacing: CGFloat = 140
        var y = rect.minY + 40
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 30 : 100)
            while x < rect.maxX {
                drawPalmTree(at: CGPoint(x: x, y: y), size: 50, context: context)
                x += spacing
            }
            y += spacing * 0.9
            row += 1
        }
    }

    private static func drawPalmTree(at center: CGPoint, size: CGFloat, context: CGContext) {
        context.setLineWidth(size * 0.06)
        context.move(to: CGPoint(x: center.x, y: center.y - size * 0.4))
        context.addLine(to: CGPoint(x: center.x + size * 0.05, y: center.y + size * 0.1))
        context.strokePath()
        for angle in stride(from: -150.0, through: -30.0, by: 30.0) {
            let rad = angle * .pi / 180
            let tipX = center.x + cos(rad) * size * 0.4
            let tipY = center.y + size * 0.1 + sin(rad) * size * 0.35
            context.move(to: CGPoint(x: center.x, y: center.y + size * 0.1))
            context.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: center.x + cos(rad) * size * 0.15, y: center.y + size * 0.15))
            context.setLineWidth(size * 0.03)
            context.strokePath()
        }
    }

    private static func drawMountains(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.3, green: 0.35, blue: 0.5, alpha: 1)
        context.setStrokeColor(color)
        let spacing: CGFloat = 160
        var y = rect.minY + 60; var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 20 : 100)
            while x < rect.maxX {
                let s: CGFloat = 55
                context.setLineWidth(s * 0.025)
                context.move(to: CGPoint(x: x - s * 0.5, y: y - s * 0.35))
                context.addLine(to: CGPoint(x: x, y: y + s * 0.35))
                context.addLine(to: CGPoint(x: x + s * 0.5, y: y - s * 0.35))
                context.strokePath()
                x += spacing
            }
            y += spacing * 0.85; row += 1
        }
    }

    private static func drawCompassPattern(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.4, green: 0.35, blue: 0.25, alpha: 1)
        context.setStrokeColor(color); context.setFillColor(color)
        let spacing: CGFloat = 180
        var y = rect.minY + 50; var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 40 : 130)
            while x < rect.maxX {
                drawSmallCompass(at: CGPoint(x: x, y: y), size: 45, context: context)
                x += spacing
            }
            y += spacing * 0.85; row += 1
        }
    }

    private static func drawSmallCompass(at center: CGPoint, size: CGFloat, context: CGContext) {
        let r = size * 0.45
        context.setLineWidth(size * 0.02)
        context.strokeEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let inner = i % 2 == 0 ? r * 0.3 : r * 0.5
            context.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * r * 0.9, y: center.y + sin(angle) * r * 0.9))
            context.strokePath()
        }
    }

    private static func drawWaves(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(CGColor(red: 0.15, green: 0.45, blue: 0.7, alpha: 1))
        context.setLineWidth(1.5)
        let wH: CGFloat = 12; let wL: CGFloat = 40; var y = rect.minY + 30
        while y < rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y))
            var x = rect.minX
            while x < rect.maxX {
                context.addQuadCurve(to: CGPoint(x: x + wL / 2, y: y), control: CGPoint(x: x + wL / 4, y: y + wH))
                context.addQuadCurve(to: CGPoint(x: x + wL, y: y), control: CGPoint(x: x + wL * 3 / 4, y: y - wH))
                x += wL
            }
            context.strokePath(); y += 50
        }
    }

    private static func drawSuitcases(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(CGColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1))
        let spacing: CGFloat = 120
        var y = rect.minY + 40; var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 25 : 85)
            while x < rect.maxX {
                let s: CGFloat = 35; let w = s * 0.7; let h = s * 0.5
                context.setLineWidth(s * 0.035)
                context.addPath(CGPath(roundedRect: CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h), cornerWidth: s * 0.06, cornerHeight: s * 0.06, transform: nil))
                context.strokePath()
                context.move(to: CGPoint(x: x - s * 0.125, y: y + h / 2))
                context.addLine(to: CGPoint(x: x - s * 0.125, y: y + h / 2 + s * 0.15))
                context.addLine(to: CGPoint(x: x + s * 0.125, y: y + h / 2 + s * 0.15))
                context.addLine(to: CGPoint(x: x + s * 0.125, y: y + h / 2))
                context.strokePath()
                x += spacing
            }
            y += spacing * 0.9; row += 1
        }
    }

    private static func drawWorldDots(in rect: CGRect, context: CGContext) {
        context.setFillColor(CGColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1))
        let seed: [CGFloat] = [0.12, 0.34, 0.56, 0.78, 0.91, 0.23, 0.45, 0.67, 0.89, 0.01, 0.15, 0.37, 0.59, 0.73, 0.88, 0.26, 0.48, 0.62, 0.84, 0.05]
        for i in 0..<seed.count {
            let bx = seed[i] * rect.width + rect.minX
            let by = seed[(i + 7) % seed.count] * rect.height + rect.minY
            for j in 0..<5 {
                let ox = seed[(i + j + 3) % seed.count] * 30 - 15
                let oy = seed[(i + j + 5) % seed.count] * 30 - 15
                let r = 2.5 * (0.5 + seed[(i + j) % seed.count] * 0.8)
                context.fillEllipse(in: CGRect(x: bx + ox - r, y: by + oy - r, width: r * 2, height: r * 2))
            }
        }
    }

    private static func drawTropicalLeaves(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(CGColor(red: 0.15, green: 0.5, blue: 0.3, alpha: 1))
        let spacing: CGFloat = 150
        var y = rect.minY + 40; var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 30 : 105)
            while x < rect.maxX {
                drawLeaf(at: CGPoint(x: x, y: y), size: 45, angle: Double(row + Int(x)) * 0.7, context: context)
                x += spacing
            }
            y += spacing * 0.85; row += 1
        }
    }

    private static func drawLeaf(at c: CGPoint, size: CGFloat, angle: Double, context: CGContext) {
        context.saveGState()
        context.translateBy(x: c.x, y: c.y); context.rotate(by: angle)
        context.setLineWidth(size * 0.025)
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addQuadCurve(to: CGPoint(x: 0, y: size * 0.45), control: CGPoint(x: size * 0.35, y: 0))
        context.strokePath()
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addQuadCurve(to: CGPoint(x: 0, y: size * 0.45), control: CGPoint(x: -size * 0.35, y: 0))
        context.strokePath()
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addLine(to: CGPoint(x: 0, y: size * 0.45))
        context.strokePath()
        context.restoreGState()
    }

    private static func drawAnchors(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(CGColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1))
        let spacing: CGFloat = 130
        var y = rect.minY + 40; var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 30 : 95)
            while x < rect.maxX {
                let s: CGFloat = 40
                context.setLineWidth(s * 0.04)
                context.move(to: CGPoint(x: x, y: y - s * 0.35))
                context.addLine(to: CGPoint(x: x, y: y + s * 0.25))
                context.strokePath()
                context.strokeEllipse(in: CGRect(x: x - s * 0.08, y: y + s * 0.25, width: s * 0.16, height: s * 0.16))
                context.move(to: CGPoint(x: x - s * 0.2, y: y + s * 0.1))
                context.addLine(to: CGPoint(x: x + s * 0.2, y: y + s * 0.1))
                context.strokePath()
                context.move(to: CGPoint(x: x, y: y - s * 0.35))
                context.addQuadCurve(to: CGPoint(x: x - s * 0.3, y: y - s * 0.15), control: CGPoint(x: x - s * 0.35, y: y - s * 0.35))
                context.strokePath()
                context.move(to: CGPoint(x: x, y: y - s * 0.35))
                context.addQuadCurve(to: CGPoint(x: x + s * 0.3, y: y - s * 0.15), control: CGPoint(x: x + s * 0.35, y: y - s * 0.35))
                context.strokePath()
                x += spacing
            }
            y += spacing * 0.9; row += 1
        }
    }

    // =====================================================================
    // MARK: - Full-Page Art Implementations
    // =====================================================================

    private static func drawBeachScene(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.1, green: 0.5, blue: 0.6, alpha: 1)
        context.setStrokeColor(color); context.setFillColor(color)

        // Sun (top right)
        let sunX = rect.maxX - rect.width * 0.2
        let sunY = rect.maxY - rect.height * 0.15
        let sunR = rect.width * 0.08
        context.setLineWidth(2)
        context.strokeEllipse(in: CGRect(x: sunX - sunR, y: sunY - sunR, width: sunR * 2, height: sunR * 2))
        for i in 0..<12 {
            let angle = Double(i) * .pi / 6
            context.move(to: CGPoint(x: sunX + cos(angle) * sunR * 1.3, y: sunY + sin(angle) * sunR * 1.3))
            context.addLine(to: CGPoint(x: sunX + cos(angle) * sunR * 1.6, y: sunY + sin(angle) * sunR * 1.6))
            context.strokePath()
        }

        // Horizon waves (bottom third)
        let horizonY = rect.minY + rect.height * 0.3
        context.setLineWidth(1.5)
        for i in 0..<4 {
            let wy = horizonY + CGFloat(i) * 15
            context.move(to: CGPoint(x: rect.minX, y: wy))
            var x = rect.minX
            while x < rect.maxX {
                context.addQuadCurve(to: CGPoint(x: x + 30, y: wy), control: CGPoint(x: x + 15, y: wy + 8))
                x += 30
            }
            context.strokePath()
        }

        // Large palm tree (left side)
        let treeX = rect.minX + rect.width * 0.15
        let treeBase = rect.minY + rect.height * 0.3
        let treeTop = rect.minY + rect.height * 0.75
        context.setLineWidth(4)
        context.move(to: CGPoint(x: treeX, y: treeBase))
        context.addQuadCurve(to: CGPoint(x: treeX + 15, y: treeTop), control: CGPoint(x: treeX - 20, y: treeBase + (treeTop - treeBase) * 0.5))
        context.strokePath()

        // Fronds
        context.setLineWidth(2)
        for angle in stride(from: -160.0, through: -20.0, by: 20.0) {
            let rad = angle * .pi / 180
            let len = rect.width * 0.12
            context.move(to: CGPoint(x: treeX + 15, y: treeTop))
            context.addQuadCurve(
                to: CGPoint(x: treeX + 15 + cos(rad) * len, y: treeTop + sin(rad) * len * 0.7),
                control: CGPoint(x: treeX + 15 + cos(rad) * len * 0.4, y: treeTop + 20)
            )
            context.strokePath()
        }

        // Beach line
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.minX, y: horizonY - 5))
        context.addQuadCurve(to: CGPoint(x: rect.maxX, y: horizonY + 10), control: CGPoint(x: rect.midX, y: horizonY - 20))
        context.strokePath()
    }

    private static func drawMountainLandscape(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.25, green: 0.3, blue: 0.45, alpha: 1)
        context.setStrokeColor(color); context.setLineWidth(2)

        let baseY = rect.minY + rect.height * 0.35
        // Background range
        let peaks1: [(CGFloat, CGFloat)] = [(0.1, 0.55), (0.25, 0.7), (0.45, 0.6), (0.6, 0.75), (0.8, 0.65), (0.95, 0.5)]
        context.move(to: CGPoint(x: rect.minX, y: baseY))
        for (px, py) in peaks1 {
            context.addLine(to: CGPoint(x: rect.minX + rect.width * px, y: rect.minY + rect.height * py))
        }
        context.addLine(to: CGPoint(x: rect.maxX, y: baseY))
        context.strokePath()

        // Foreground range (larger)
        context.setLineWidth(2.5)
        let peaks2: [(CGFloat, CGFloat)] = [(0.05, 0.4), (0.2, 0.58), (0.35, 0.48), (0.5, 0.65), (0.65, 0.5), (0.85, 0.55), (0.95, 0.42)]
        context.move(to: CGPoint(x: rect.minX, y: baseY - 20))
        for (px, py) in peaks2 {
            context.addLine(to: CGPoint(x: rect.minX + rect.width * px, y: rect.minY + rect.height * py))
        }
        context.addLine(to: CGPoint(x: rect.maxX, y: baseY - 20))
        context.strokePath()

        // Pine trees at base
        context.setLineWidth(1)
        for i in stride(from: 0.05, through: 0.95, by: 0.06) {
            let tx = rect.minX + rect.width * i
            let th: CGFloat = 20 + CGFloat(Int(i * 100) % 3) * 8
            context.move(to: CGPoint(x: tx, y: baseY - 25))
            context.addLine(to: CGPoint(x: tx, y: baseY - 25 + th))
            context.addLine(to: CGPoint(x: tx - 6, y: baseY - 25))
            context.addLine(to: CGPoint(x: tx + 6, y: baseY - 25))
            context.strokePath()
        }
    }

    private static func drawLargeCompass(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.35, green: 0.3, blue: 0.2, alpha: 1)
        context.setStrokeColor(color); context.setFillColor(color)

        let cx = rect.midX; let cy = rect.midY
        let r = min(rect.width, rect.height) * 0.35

        // Outer rings
        context.setLineWidth(2)
        context.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        context.setLineWidth(1)
        context.strokeEllipse(in: CGRect(x: cx - r * 0.95, y: cy - r * 0.95, width: r * 1.9, height: r * 1.9))

        // Degree marks
        for i in 0..<36 {
            let angle = Double(i) * .pi / 18
            let inner = i % 9 == 0 ? r * 0.8 : (i % 3 == 0 ? r * 0.85 : r * 0.9)
            context.move(to: CGPoint(x: cx + cos(angle) * inner, y: cy + sin(angle) * inner))
            context.addLine(to: CGPoint(x: cx + cos(angle) * r * 0.93, y: cy + sin(angle) * r * 0.93))
            context.strokePath()
        }

        // Cardinal points (star)
        context.setLineWidth(1.5)
        let directions: [(Double, CGFloat)] = [(0, r * 0.75), (.pi / 2, r * 0.75), (.pi, r * 0.75), (.pi * 1.5, r * 0.75)]
        for (angle, len) in directions {
            let tipX = cx + cos(angle) * len; let tipY = cy + sin(angle) * len
            let sideAngle1 = angle + 0.15; let sideAngle2 = angle - 0.15
            let sideLen = len * 0.15
            context.move(to: CGPoint(x: cx, y: cy))
            context.addLine(to: CGPoint(x: cx + cos(sideAngle1) * sideLen, y: cy + sin(sideAngle1) * sideLen))
            context.addLine(to: CGPoint(x: tipX, y: tipY))
            context.addLine(to: CGPoint(x: cx + cos(sideAngle2) * sideLen, y: cy + sin(sideAngle2) * sideLen))
            context.closePath()
            context.strokePath()
        }

        // Intercardinal points (smaller)
        for i in 0..<4 {
            let angle = Double(i) * .pi / 2 + .pi / 4
            let len = r * 0.5
            context.move(to: CGPoint(x: cx, y: cy))
            context.addLine(to: CGPoint(x: cx + cos(angle) * len, y: cy + sin(angle) * len))
            context.strokePath()
        }

        // Center
        context.fillEllipse(in: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8))

        // N, S, E, W labels
        let labelFont = NSFont.systemFont(ofSize: 14, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: NSColor(cgColor: color) ?? .gray]
        NSAttributedString(string: "N", attributes: attrs).draw(at: NSPoint(x: cx - 5, y: cy + r * 0.75 + 4))
        NSAttributedString(string: "S", attributes: attrs).draw(at: NSPoint(x: cx - 4, y: cy - r * 0.75 - 20))
        NSAttributedString(string: "E", attributes: attrs).draw(at: NSPoint(x: cx + r * 0.75 + 6, y: cy - 8))
        NSAttributedString(string: "W", attributes: attrs).draw(at: NSPoint(x: cx - r * 0.75 - 20, y: cy - 8))
    }

    private static func drawWorldMapOutline(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1)
        context.setFillColor(color)

        // Simplified continent shapes as dot clusters
        let continents: [(xRange: ClosedRange<CGFloat>, yRange: ClosedRange<CGFloat>, density: Int)] = [
            (0.15...0.30, 0.50...0.80, 40),   // North America
            (0.20...0.30, 0.30...0.50, 25),   // Central America
            (0.22...0.35, 0.10...0.35, 35),   // South America
            (0.42...0.55, 0.50...0.85, 45),   // Europe
            (0.45...0.60, 0.20...0.55, 50),   // Africa
            (0.60...0.80, 0.50...0.80, 45),   // Asia
            (0.72...0.85, 0.15...0.30, 30),   // Australia
        ]

        for cont in continents {
            for _ in 0..<cont.density {
                let fx = CGFloat.random(in: cont.xRange)
                let fy = CGFloat.random(in: cont.yRange)
                let x = rect.minX + rect.width * fx
                let y = rect.minY + rect.height * fy
                let r: CGFloat = CGFloat.random(in: 1.5...3.5)
                context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }

        // Grid lines
        context.setStrokeColor(color); context.setLineWidth(0.5)
        for i in 1..<6 {
            let y = rect.minY + rect.height * CGFloat(i) / 6
            context.move(to: CGPoint(x: rect.minX + 20, y: y))
            context.addLine(to: CGPoint(x: rect.maxX - 20, y: y))
            context.strokePath()
        }
        for i in 1..<8 {
            let x = rect.minX + rect.width * CGFloat(i) / 8
            context.move(to: CGPoint(x: x, y: rect.minY + 20))
            context.addLine(to: CGPoint(x: x, y: rect.maxY - 20))
            context.strokePath()
        }
    }

    private static func drawTropicalFrame(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.12, green: 0.5, blue: 0.35, alpha: 1)
        context.setStrokeColor(color); context.setLineWidth(2)

        let inset: CGFloat = 30
        // Corner clusters of leaves
        let corners = [
            CGPoint(x: rect.minX + inset, y: rect.minY + inset),
            CGPoint(x: rect.maxX - inset, y: rect.minY + inset),
            CGPoint(x: rect.minX + inset, y: rect.maxY - inset),
            CGPoint(x: rect.maxX - inset, y: rect.maxY - inset),
        ]
        for (i, corner) in corners.enumerated() {
            for j in 0..<5 {
                let angle = Double(j) * 0.4 + Double(i) * 1.5 + 0.3
                drawLeaf(at: corner, size: 60 + CGFloat(j) * 8, angle: angle, context: context)
            }
        }

        // Side vines
        context.setLineWidth(1.5)
        let midLeft = CGPoint(x: rect.minX + inset, y: rect.midY)
        let midRight = CGPoint(x: rect.maxX - inset, y: rect.midY)
        for side in [midLeft, midRight] {
            for j in 0..<3 {
                drawLeaf(at: CGPoint(x: side.x, y: side.y + CGFloat(j - 1) * 40), size: 40, angle: Double(j) * 0.8, context: context)
            }
        }
    }

    private static func drawNauticalChart(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.2, green: 0.35, blue: 0.5, alpha: 1)
        context.setStrokeColor(color)

        // Grid
        context.setLineWidth(0.5)
        let gridSpacing: CGFloat = 40
        var x = rect.minX + 20
        while x < rect.maxX - 20 {
            context.move(to: CGPoint(x: x, y: rect.minY + 20))
            context.addLine(to: CGPoint(x: x, y: rect.maxY - 20))
            context.strokePath()
            x += gridSpacing
        }
        var y = rect.minY + 20
        while y < rect.maxY - 20 {
            context.move(to: CGPoint(x: rect.minX + 20, y: y))
            context.addLine(to: CGPoint(x: rect.maxX - 20, y: y))
            context.strokePath()
            y += gridSpacing
        }

        // Compass rose in center
        drawSmallCompass(at: CGPoint(x: rect.midX, y: rect.midY), size: min(rect.width, rect.height) * 0.2, context: context)

        // Depth soundings (scattered numbers)
        let font = NSFont.systemFont(ofSize: 7, weight: .light)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color) ?? .gray]
        let depths = ["12", "8", "15", "6", "22", "9", "18", "4", "11", "7", "20", "14"]
        let positions: [(CGFloat, CGFloat)] = [(0.2, 0.25), (0.4, 0.7), (0.7, 0.3), (0.15, 0.6), (0.85, 0.5), (0.5, 0.15), (0.3, 0.85), (0.75, 0.75), (0.6, 0.45), (0.25, 0.45), (0.8, 0.2), (0.55, 0.85)]
        for (i, pos) in positions.enumerated() {
            let dx = rect.minX + rect.width * pos.0
            let dy = rect.minY + rect.height * pos.1
            NSAttributedString(string: depths[i], attributes: attrs).draw(at: NSPoint(x: dx, y: dy))
        }
    }

    // =====================================================================
    // MARK: - Border Implementations
    // =====================================================================

    private static func drawSimpleBorder(in rect: CGRect, context: CGContext) {
        context.setStrokeColor(CGColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 1))
        context.setLineWidth(2)
        let inset: CGFloat = 24
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: inset, dy: inset), cornerWidth: 8, cornerHeight: 8, transform: nil))
        context.strokePath()
    }

    private static func drawDoubleBorder(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.1, green: 0.55, blue: 0.55, alpha: 1)
        context.setStrokeColor(color)
        context.setLineWidth(2)
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: 20, dy: 20), cornerWidth: 8, cornerHeight: 8, transform: nil))
        context.strokePath()
        context.setLineWidth(0.8)
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: 26, dy: 26), cornerWidth: 6, cornerHeight: 6, transform: nil))
        context.strokePath()
    }

    private static func drawRopeBorder(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.45, green: 0.35, blue: 0.2, alpha: 1)
        context.setStrokeColor(color)
        let inset: CGFloat = 22
        let r = rect.insetBy(dx: inset, dy: inset)

        // Two intertwined lines
        context.setLineWidth(2.5)
        let dashPattern: [CGFloat] = [8, 6]
        context.setLineDash(phase: 0, lengths: dashPattern)
        context.addPath(CGPath(roundedRect: r, cornerWidth: 10, cornerHeight: 10, transform: nil))
        context.strokePath()

        context.setLineDash(phase: 7, lengths: dashPattern)
        context.addPath(CGPath(roundedRect: r, cornerWidth: 10, cornerHeight: 10, transform: nil))
        context.strokePath()

        context.setLineDash(phase: 0, lengths: [])
    }

    private static func drawVineBorder(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.15, green: 0.5, blue: 0.3, alpha: 1)
        context.setStrokeColor(color); context.setLineWidth(1.5)
        let inset: CGFloat = 20

        // Main vine line
        let r = rect.insetBy(dx: inset, dy: inset)
        context.addPath(CGPath(roundedRect: r, cornerWidth: 6, cornerHeight: 6, transform: nil))
        context.strokePath()

        // Leaves along the border
        let leafSize: CGFloat = 12
        let spacing: CGFloat = 35
        // Top
        var x = r.minX + 20
        while x < r.maxX - 20 {
            drawMiniLeaf(at: CGPoint(x: x, y: r.maxY), size: leafSize, angle: .pi / 2, context: context)
            x += spacing
        }
        // Bottom
        x = r.minX + 20
        while x < r.maxX - 20 {
            drawMiniLeaf(at: CGPoint(x: x, y: r.minY), size: leafSize, angle: -.pi / 2, context: context)
            x += spacing
        }
        // Left
        var y = r.minY + 20
        while y < r.maxY - 20 {
            drawMiniLeaf(at: CGPoint(x: r.minX, y: y), size: leafSize, angle: .pi, context: context)
            y += spacing
        }
        // Right
        y = r.minY + 20
        while y < r.maxY - 20 {
            drawMiniLeaf(at: CGPoint(x: r.maxX, y: y), size: leafSize, angle: 0, context: context)
            y += spacing
        }
    }

    private static func drawMiniLeaf(at c: CGPoint, size: CGFloat, angle: Double, context: CGContext) {
        context.saveGState()
        context.translateBy(x: c.x, y: c.y); context.rotate(by: angle)
        context.move(to: .zero)
        context.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size * 0.5, y: size * 0.4))
        context.move(to: .zero)
        context.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size * 0.5, y: -size * 0.4))
        context.strokePath()
        context.restoreGState()
    }

    private static func drawPassportBorder(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.3, green: 0.25, blue: 0.4, alpha: 1)
        context.setStrokeColor(color)
        let inset: CGFloat = 20

        // Scattered "stamp" circles along edges
        let stamps: [(CGFloat, CGFloat, CGFloat)] = [ // x-fraction, y-fraction, radius
            (0.1, 0.02, 25), (0.4, 0.03, 20), (0.7, 0.02, 22), (0.9, 0.04, 18),
            (0.1, 0.97, 22), (0.35, 0.98, 20), (0.65, 0.96, 25), (0.85, 0.98, 18),
            (0.02, 0.2, 20), (0.03, 0.5, 22), (0.02, 0.8, 18),
            (0.97, 0.25, 18), (0.98, 0.55, 20), (0.97, 0.75, 22),
        ]

        for stamp in stamps {
            let cx = rect.minX + rect.width * stamp.0
            let cy = rect.minY + rect.height * stamp.1
            let r = stamp.2
            context.setLineWidth(1.5)
            context.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            // Inner circle
            context.setLineWidth(0.5)
            context.strokeEllipse(in: CGRect(x: cx - r * 0.7, y: cy - r * 0.7, width: r * 1.4, height: r * 1.4))
        }
    }

    private static func drawTicketBorder(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1)
        context.setStrokeColor(color); context.setLineWidth(1.5)
        let inset: CGFloat = 18

        // Perforated edge (dashed line with semicircle cutouts)
        let r = rect.insetBy(dx: inset, dy: inset)
        let notchR: CGFloat = 4
        let spacing: CGFloat = 20

        // Top edge
        var x = r.minX + spacing / 2
        while x < r.maxX {
            context.fillEllipse(in: CGRect(x: x - notchR, y: r.maxY - notchR, width: notchR * 2, height: notchR * 2))
            x += spacing
        }
        // Bottom edge
        x = r.minX + spacing / 2
        while x < r.maxX {
            context.fillEllipse(in: CGRect(x: x - notchR, y: r.minY - notchR, width: notchR * 2, height: notchR * 2))
            x += spacing
        }
        // Left edge
        var y = r.minY + spacing / 2
        while y < r.maxY {
            context.fillEllipse(in: CGRect(x: r.minX - notchR, y: y - notchR, width: notchR * 2, height: notchR * 2))
            y += spacing
        }
        // Right edge
        y = r.minY + spacing / 2
        while y < r.maxY {
            context.fillEllipse(in: CGRect(x: r.maxX - notchR, y: y - notchR, width: notchR * 2, height: notchR * 2))
            y += spacing
        }

        // Outer frame
        context.addPath(CGPath(roundedRect: r, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.strokePath()
    }
}
