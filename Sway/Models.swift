import Foundation

func bounded(_ value: Double) -> Double { min(1, max(0, value)) }
struct Adjustment {
    let initial: Double
    let origin: Double
    func value(at position: Double, width: Double) -> Double {
        bounded(initial + (position - origin) / max(width, 1))
    }
    func isSwipe(at position: Double) -> Bool { abs(position - origin) >= 4 }
}

func isAppWindow(layer: Int, width: Double, height: Double, alpha: Double) -> Bool {
    layer == 0 && width > 1 && height > 1 && alpha > 0
}

// macOS OSD graphic identifiers; no custom overlay is drawn.
enum HUDKind: Int64 {
    case brightness = 1
    case volume = 3
    case muted = 4
    case keyboard = 25
}
