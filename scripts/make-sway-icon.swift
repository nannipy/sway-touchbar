import AppKit

// Code-native vector mark, rendered at every macOS app-icon resolution.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 196, yRadius: 196).fill()
        let wave = NSBezierPath()
        wave.move(to: NSPoint(x: 700, y: 704))
        wave.curve(to: NSPoint(x: 336, y: 615), controlPoint1: NSPoint(x: 495, y: 845), controlPoint2: NSPoint(x: 222, y: 738))
        wave.curve(to: NSPoint(x: 690, y: 392), controlPoint1: NSPoint(x: 420, y: 520), controlPoint2: NSPoint(x: 793, y: 509))
        wave.curve(to: NSPoint(x: 324, y: 315), controlPoint1: NSPoint(x: 590, y: 264), controlPoint2: NSPoint(x: 434, y: 251))
        wave.lineWidth = 87
        wave.lineCapStyle = .round
        NSColor.white.setStroke(); wave.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
