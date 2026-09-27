import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Finder paints this under the title bar, so the pixel size is the content area, not the whole window.
let points = CGSize(width: 680, height: 400)
let scale: CGFloat = 2

let outURL: URL
if CommandLine.arguments.count > 1 {
    outURL = URL(fileURLWithPath: CommandLine.arguments[1])
} else {
    fputs("usage: dmg-background.swift <output.png>\n", stderr)
    exit(1)
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(points.width * scale),
    pixelsHigh: Int(points.height * scale),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
rep.size = NSSize(width: points.width, height: points.height)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

color(0xF4F5F7).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: NSSize(width: points.width, height: points.height))).fill()

ctx.saveGState()
ctx.setStrokeColor(color(0xE1E3E8).cgColor)
ctx.setLineWidth(1)
var x: CGFloat = 0
while x <= points.width {
    ctx.move(to: CGPoint(x: x + 0.5, y: 0))
    ctx.addLine(to: CGPoint(x: x + 0.5, y: points.height))
    x += 48
}
var y: CGFloat = 0
while y <= points.height {
    ctx.move(to: CGPoint(x: 0, y: y + 0.5))
    ctx.addLine(to: CGPoint(x: points.width, y: y + 0.5))
    y += 48
}
ctx.strokePath()
ctx.restoreGState()

let title = NSAttributedString(
    string: "Grid Walk",
    attributes: [
        .font: NSFont.systemFont(ofSize: 34, weight: .semibold),
        .foregroundColor: color(0x0E0F12),
        .kern: -0.8,
    ]
)
let titleSize = title.size()
title.draw(at: NSPoint(x: (points.width - titleSize.width) / 2, y: points.height - 78))

let subtitle = NSAttributedString(
    string: "Drag to Applications",
    attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .regular),
        .foregroundColor: color(0x5A5F68),
    ]
)
let subtitleSize = subtitle.size()
subtitle.draw(at: NSPoint(x: (points.width - subtitleSize.width) / 2, y: points.height - 110))

let version = NSAttributedString(
    string: "1.0.0",
    attributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: color(0x5A5F68),
    ]
)
let versionSize = version.size()
version.draw(at: NSPoint(x: (points.width - versionSize.width) / 2, y: points.height - 136))

// Icon centers sit at y 210, in the middle of the window.
let arrowY: CGFloat = points.height - 210
let arrowStart: CGFloat = 268
let arrowTip: CGFloat = 412
ctx.saveGState()
ctx.setStrokeColor(color(0xD70015).cgColor)
ctx.setLineWidth(2)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: arrowStart, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowTip, y: arrowY))
ctx.move(to: CGPoint(x: arrowTip - 12, y: arrowY + 8))
ctx.addLine(to: CGPoint(x: arrowTip, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowTip - 12, y: arrowY - 8))
ctx.strokePath()
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let cgImage = rep.cgImage else { exit(1) }
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    exit(1)
}
let props: [CFString: Any] = [
    kCGImagePropertyDPIWidth: 144,
    kCGImagePropertyDPIHeight: 144,
]
CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
if !CGImageDestinationFinalize(dest) { exit(1) }
