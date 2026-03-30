#!/usr/bin/env swift

import AppKit
import CoreGraphics

/// Generates a macOS app icon with a suitcase/packing design.
func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let inset = size * 0.05
    let roundedRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cornerRadius = size * 0.22

    // Background: warm teal gradient
    let bgPath = CGPath(roundedRect: roundedRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(bgPath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.10, green: 0.55, blue: 0.55, alpha: 1.0),
        CGColor(red: 0.05, green: 0.30, blue: 0.35, alpha: 1.0),
    ]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0.0, 1.0]) {
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: size),
                                   end: CGPoint(x: size, y: 0),
                                   options: [])
    }

    let center = CGPoint(x: size / 2, y: size / 2)

    // Suitcase body
    let caseWidth = size * 0.54
    let caseHeight = size * 0.40
    let caseBottom = center.y - caseHeight * 0.55
    let caseLeft = center.x - caseWidth / 2
    let caseCorner = size * 0.05

    let caseRect = CGRect(x: caseLeft, y: caseBottom, width: caseWidth, height: caseHeight)
    let casePath = CGPath(roundedRect: caseRect, cornerWidth: caseCorner, cornerHeight: caseCorner, transform: nil)

    // Suitcase fill
    context.saveGState()
    context.addPath(casePath)
    context.clip()
    let caseColors = [
        CGColor(red: 0.95, green: 0.75, blue: 0.35, alpha: 0.9),
        CGColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 0.9),
    ]
    if let caseGradient = CGGradient(colorsSpace: colorSpace, colors: caseColors as CFArray, locations: [0.0, 1.0]) {
        context.drawLinearGradient(caseGradient,
                                   start: CGPoint(x: 0, y: caseBottom + caseHeight),
                                   end: CGPoint(x: 0, y: caseBottom),
                                   options: [])
    }
    context.restoreGState()

    // Suitcase outline
    context.addPath(casePath)
    context.setStrokeColor(CGColor(red: 0.70, green: 0.45, blue: 0.15, alpha: 0.8))
    context.setLineWidth(size * 0.012)
    context.strokePath()

    // Handle on top
    let handleWidth = size * 0.20
    let handleHeight = size * 0.10
    let handleLeft = center.x - handleWidth / 2
    let handleBottom = caseBottom + caseHeight - size * 0.01
    let handleCorner = size * 0.03

    let handleRect = CGRect(x: handleLeft, y: handleBottom, width: handleWidth, height: handleHeight)
    let handlePath = CGPath(roundedRect: handleRect, cornerWidth: handleCorner, cornerHeight: handleCorner, transform: nil)
    context.addPath(handlePath)
    context.setStrokeColor(CGColor(red: 0.70, green: 0.45, blue: 0.15, alpha: 0.9))
    context.setLineWidth(size * 0.02)
    context.setFillColor(CGColor(red: 0.10, green: 0.55, blue: 0.55, alpha: 1.0))
    context.drawPath(using: .fillStroke)

    // Belt/strap across the suitcase
    let beltY = caseBottom + caseHeight * 0.45
    let beltHeight = size * 0.035
    context.setFillColor(CGColor(red: 0.70, green: 0.45, blue: 0.15, alpha: 0.6))
    context.fill(CGRect(x: caseLeft, y: beltY, width: caseWidth, height: beltHeight))

    // Belt buckle
    let buckleSize = size * 0.05
    let buckleRect = CGRect(x: center.x - buckleSize / 2, y: beltY + (beltHeight - buckleSize) / 2,
                            width: buckleSize, height: buckleSize)
    context.setFillColor(CGColor(red: 0.90, green: 0.80, blue: 0.55, alpha: 1.0))
    context.fill(buckleRect)

    // Checkmark overlay (bottom-right)
    let checkCenterX = center.x + size * 0.18
    let checkCenterY = caseBottom - size * 0.02
    let checkRadius = size * 0.10

    // Check circle background
    context.setFillColor(CGColor(red: 0.30, green: 0.78, blue: 0.45, alpha: 0.95))
    context.fillEllipse(in: CGRect(x: checkCenterX - checkRadius, y: checkCenterY - checkRadius,
                                    width: checkRadius * 2, height: checkRadius * 2))

    // Checkmark
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    context.setLineWidth(size * 0.02)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: checkCenterX - checkRadius * 0.4, y: checkCenterY))
    context.addLine(to: CGPoint(x: checkCenterX - checkRadius * 0.1, y: checkCenterY - checkRadius * 0.35))
    context.addLine(to: CGPoint(x: checkCenterX + checkRadius * 0.4, y: checkCenterY + checkRadius * 0.35))
    context.strokePath()

    image.unlockFocus()
    return image
}

let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = renderIcon(size: size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(name)")
        continue
    }
    let path = "\(iconsetPath)/\(name).png"
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("Generated \(path) (\(Int(size))x\(Int(size)))")
}

print("\nConverting to .icns...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Created AppIcon.icns")
} else {
    print("iconutil failed")
}

try? fm.removeItem(atPath: iconsetPath)
