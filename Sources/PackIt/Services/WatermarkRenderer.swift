import AppKit
import CoreGraphics

struct WatermarkRenderer {
    /// Base opacity for all watermarks — subtle enough to print text over.
    static let opacity: CGFloat = 0.06

    static func draw(style: WatermarkStyle, in rect: CGRect, context: CGContext) {
        guard style != .none else { return }
        context.saveGState()
        context.setAlpha(opacity)

        switch style {
        case .none: break
        case .palmTrees: drawPalmTrees(in: rect, context: context)
        case .mountains: drawMountains(in: rect, context: context)
        case .compass: drawCompass(in: rect, context: context)
        case .waves: drawWaves(in: rect, context: context)
        case .suitcases: drawSuitcases(in: rect, context: context)
        case .worldDots: drawWorldDots(in: rect, context: context)
        case .tropicalLeaves: drawTropicalLeaves(in: rect, context: context)
        case .anchors: drawAnchors(in: rect, context: context)
        }

        context.restoreGState()
    }

    // MARK: - Palm Trees

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
        // Trunk
        context.setLineWidth(size * 0.06)
        context.move(to: CGPoint(x: center.x, y: center.y - size * 0.4))
        context.addLine(to: CGPoint(x: center.x + size * 0.05, y: center.y + size * 0.1))
        context.strokePath()

        // Fronds
        for angle in stride(from: -150.0, through: -30.0, by: 30.0) {
            let rad = angle * .pi / 180
            let tipX = center.x + cos(rad) * size * 0.4
            let tipY = center.y + size * 0.1 + sin(rad) * size * 0.35
            let cp1X = center.x + cos(rad) * size * 0.15
            let cp1Y = center.y + size * 0.15
            context.move(to: CGPoint(x: center.x, y: center.y + size * 0.1))
            context.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: cp1X, y: cp1Y))
            context.setLineWidth(size * 0.03)
            context.strokePath()
        }
    }

    // MARK: - Mountains

    private static func drawMountains(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.3, green: 0.35, blue: 0.5, alpha: 1)
        context.setStrokeColor(color)
        context.setFillColor(color)

        let spacing: CGFloat = 160
        var y = rect.minY + 60
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 20 : 100)
            while x < rect.maxX {
                drawMountain(at: CGPoint(x: x, y: y), size: 55, context: context)
                x += spacing
            }
            y += spacing * 0.85
            row += 1
        }
    }

    private static func drawMountain(at center: CGPoint, size: CGFloat, context: CGContext) {
        // Main peak
        context.move(to: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.35))
        context.addLine(to: CGPoint(x: center.x - size * 0.05, y: center.y + size * 0.35))
        context.addLine(to: CGPoint(x: center.x + size * 0.15, y: center.y + size * 0.15))
        context.addLine(to: CGPoint(x: center.x + size * 0.35, y: center.y + size * 0.35))
        context.addLine(to: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.35))
        context.setLineWidth(size * 0.025)
        context.strokePath()

        // Snow cap
        context.move(to: CGPoint(x: center.x - size * 0.12, y: center.y + size * 0.2))
        context.addLine(to: CGPoint(x: center.x - size * 0.05, y: center.y + size * 0.35))
        context.addLine(to: CGPoint(x: center.x + size * 0.03, y: center.y + size * 0.25))
        context.setLineWidth(size * 0.02)
        context.strokePath()
    }

    // MARK: - Compass

    private static func drawCompass(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.4, green: 0.35, blue: 0.25, alpha: 1)
        context.setStrokeColor(color)

        let spacing: CGFloat = 180
        var y = rect.minY + 50
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 40 : 130)
            while x < rect.maxX {
                drawCompassRose(at: CGPoint(x: x, y: y), size: 45, context: context)
                x += spacing
            }
            y += spacing * 0.85
            row += 1
        }
    }

    private static func drawCompassRose(at center: CGPoint, size: CGFloat, context: CGContext) {
        let r = size * 0.45
        context.setLineWidth(size * 0.02)

        // Outer circle
        context.strokeEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))

        // Cardinal points
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let inner = i % 2 == 0 ? r * 0.3 : r * 0.5
            let outer = r * 0.9
            context.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
            context.strokePath()
        }

        // Center dot
        let dotR = size * 0.04
        context.fillEllipse(in: CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))
    }

    // MARK: - Waves

    private static func drawWaves(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.15, green: 0.45, blue: 0.7, alpha: 1)
        context.setStrokeColor(color)
        context.setLineWidth(1.5)

        let waveHeight: CGFloat = 12
        let waveLength: CGFloat = 40
        let spacing: CGFloat = 50
        var y = rect.minY + 30

        while y < rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y))
            var x = rect.minX
            while x < rect.maxX {
                context.addQuadCurve(
                    to: CGPoint(x: x + waveLength / 2, y: y),
                    control: CGPoint(x: x + waveLength / 4, y: y + waveHeight)
                )
                context.addQuadCurve(
                    to: CGPoint(x: x + waveLength, y: y),
                    control: CGPoint(x: x + waveLength * 3 / 4, y: y - waveHeight)
                )
                x += waveLength
            }
            context.strokePath()
            y += spacing
        }
    }

    // MARK: - Suitcases

    private static func drawSuitcases(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1)
        context.setStrokeColor(color)

        let spacing: CGFloat = 120
        var y = rect.minY + 40
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 25 : 85)
            while x < rect.maxX {
                drawSuitcase(at: CGPoint(x: x, y: y), size: 35, context: context)
                x += spacing
            }
            y += spacing * 0.9
            row += 1
        }
    }

    private static func drawSuitcase(at center: CGPoint, size: CGFloat, context: CGContext) {
        let w = size * 0.7
        let h = size * 0.5
        let r = size * 0.06
        context.setLineWidth(size * 0.035)

        // Body
        let body = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
        context.addPath(CGPath(roundedRect: body, cornerWidth: r, cornerHeight: r, transform: nil))
        context.strokePath()

        // Handle
        let handleW = size * 0.25
        let handleH = size * 0.15
        context.move(to: CGPoint(x: center.x - handleW / 2, y: center.y + h / 2))
        context.addLine(to: CGPoint(x: center.x - handleW / 2, y: center.y + h / 2 + handleH))
        context.addLine(to: CGPoint(x: center.x + handleW / 2, y: center.y + h / 2 + handleH))
        context.addLine(to: CGPoint(x: center.x + handleW / 2, y: center.y + h / 2))
        context.strokePath()

        // Belt
        context.move(to: CGPoint(x: center.x - w / 2, y: center.y))
        context.addLine(to: CGPoint(x: center.x + w / 2, y: center.y))
        context.setLineWidth(size * 0.02)
        context.strokePath()
    }

    // MARK: - World Dots

    private static func drawWorldDots(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1)
        context.setFillColor(color)

        // Scattered dots in a semi-random but deterministic pattern
        let seed: [CGFloat] = [0.12, 0.34, 0.56, 0.78, 0.91, 0.23, 0.45, 0.67, 0.89, 0.01,
                                0.15, 0.37, 0.59, 0.73, 0.88, 0.26, 0.48, 0.62, 0.84, 0.05]
        let dotR: CGFloat = 2.5

        for i in 0..<seed.count {
            let baseX = seed[i] * rect.width + rect.minX
            let baseY = seed[(i + 7) % seed.count] * rect.height + rect.minY
            // Cluster of dots around each point
            for j in 0..<5 {
                let ox = seed[(i + j + 3) % seed.count] * 30 - 15
                let oy = seed[(i + j + 5) % seed.count] * 30 - 15
                let r = dotR * (0.5 + seed[(i + j) % seed.count] * 0.8)
                context.fillEllipse(in: CGRect(x: baseX + ox - r, y: baseY + oy - r, width: r * 2, height: r * 2))
            }
        }
    }

    // MARK: - Tropical Leaves

    private static func drawTropicalLeaves(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.15, green: 0.5, blue: 0.3, alpha: 1)
        context.setStrokeColor(color)

        let spacing: CGFloat = 150
        var y = rect.minY + 40
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 30 : 105)
            while x < rect.maxX {
                drawLeaf(at: CGPoint(x: x, y: y), size: 45, angle: Double(row + Int(x)) * 0.7, context: context)
                x += spacing
            }
            y += spacing * 0.85
            row += 1
        }
    }

    private static func drawLeaf(at center: CGPoint, size: CGFloat, angle: Double, context: CGContext) {
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle)
        context.setLineWidth(size * 0.025)

        // Leaf outline
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addQuadCurve(to: CGPoint(x: 0, y: size * 0.45), control: CGPoint(x: size * 0.35, y: 0))
        context.strokePath()
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addQuadCurve(to: CGPoint(x: 0, y: size * 0.45), control: CGPoint(x: -size * 0.35, y: 0))
        context.strokePath()

        // Center vein
        context.move(to: CGPoint(x: 0, y: -size * 0.45))
        context.addLine(to: CGPoint(x: 0, y: size * 0.45))
        context.strokePath()

        // Side veins
        for t in stride(from: -0.3, through: 0.3, by: 0.15) {
            let vy = t * size
            context.move(to: CGPoint(x: 0, y: vy))
            context.addLine(to: CGPoint(x: size * 0.2, y: vy + size * 0.08))
            context.move(to: CGPoint(x: 0, y: vy))
            context.addLine(to: CGPoint(x: -size * 0.2, y: vy + size * 0.08))
        }
        context.strokePath()

        context.restoreGState()
    }

    // MARK: - Anchors

    private static func drawAnchors(in rect: CGRect, context: CGContext) {
        let color = CGColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1)
        context.setStrokeColor(color)

        let spacing: CGFloat = 130
        var y = rect.minY + 40
        var row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 30 : 95)
            while x < rect.maxX {
                drawAnchor(at: CGPoint(x: x, y: y), size: 40, context: context)
                x += spacing
            }
            y += spacing * 0.9
            row += 1
        }
    }

    private static func drawAnchor(at center: CGPoint, size: CGFloat, context: CGContext) {
        context.setLineWidth(size * 0.04)

        // Shank (vertical line)
        context.move(to: CGPoint(x: center.x, y: center.y - size * 0.35))
        context.addLine(to: CGPoint(x: center.x, y: center.y + size * 0.25))
        context.strokePath()

        // Ring at top
        let ringR = size * 0.08
        context.strokeEllipse(in: CGRect(x: center.x - ringR, y: center.y + size * 0.25, width: ringR * 2, height: ringR * 2))

        // Cross bar
        context.move(to: CGPoint(x: center.x - size * 0.2, y: center.y + size * 0.1))
        context.addLine(to: CGPoint(x: center.x + size * 0.2, y: center.y + size * 0.1))
        context.strokePath()

        // Flukes (curved arms at bottom)
        context.move(to: CGPoint(x: center.x, y: center.y - size * 0.35))
        context.addQuadCurve(
            to: CGPoint(x: center.x - size * 0.3, y: center.y - size * 0.15),
            control: CGPoint(x: center.x - size * 0.35, y: center.y - size * 0.35)
        )
        context.strokePath()

        context.move(to: CGPoint(x: center.x, y: center.y - size * 0.35))
        context.addQuadCurve(
            to: CGPoint(x: center.x + size * 0.3, y: center.y - size * 0.15),
            control: CGPoint(x: center.x + size * 0.35, y: center.y - size * 0.35)
        )
        context.strokePath()
    }
}
