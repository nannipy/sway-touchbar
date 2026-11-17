import Foundation
import CoreGraphics

enum BarZone: String, Codable, CaseIterable {
    case left, center, right
    var title: String { switch self { case .left: return "Sinistra"; case .center: return "Centro"; case .right: return "Destra" } }
}
enum BarWidget: String, Codable, CaseIterable {
    case apps, date, battery, clock, light, keyboard, audio, tailscale
    var title: String {
        switch self {
        case .apps: return "Applicazioni aperte"
        case .date: return "Data"
        case .battery: return "Batteria e percentuale"
        case .clock: return "Orario"
        case .light: return "Luminosità display"
        case .keyboard: return "Luminosità tastiera"
        case .audio: return "Volume e muto"
        case .tailscale: return "Tailscale"
        }
    }
    var defaultZone: BarZone {
        switch self { case .apps: return .left; case .date, .battery, .clock: return .center; default: return .right }
    }
}
struct BarEntry: Codable, Equatable {
    var widget: BarWidget
    var zone: BarZone
    var visible: Bool
}
struct BarLayout: Equatable {
    static let defaults = BarWidget.allCases.map { BarEntry(widget: $0, zone: $0.defaultZone, visible: true) }
    var entries: [BarEntry]
    init(entries: [BarEntry] = defaults) {
        var seen = Set<BarWidget>()
        self.entries = entries.filter { seen.insert($0.widget).inserted }
        self.entries += Self.defaults.filter { !seen.contains($0.widget) }
    }
    func widgets(in zone: BarZone) -> [BarWidget] { entries.filter { $0.visible && $0.zone == zone }.map(\.widget) }
    mutating func move(from source: Int, to destination: Int) {
        guard entries.indices.contains(source), destination >= 0, destination <= entries.count else { return }
        let entry = entries.remove(at: source)
        entries.insert(entry, at: min(entries.count, destination > source ? destination - 1 : destination))
    }
    static let storageKey = "sway.barLayout.v1"
    static func load(from defaults: UserDefaults = .standard) -> BarLayout {
        guard let data = defaults.data(forKey: storageKey),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return BarLayout() }
        // Decode each row independently: future/removed widget IDs don't discard other preferences.
        let entries = rows.compactMap { row -> BarEntry? in
            guard let id = row["widget"] as? String, let widget = BarWidget(rawValue: id),
                  let position = row["zone"] as? String, let zone = BarZone(rawValue: position),
                  let visible = row["visible"] as? Bool else { return nil }
            return BarEntry(widget: widget, zone: zone, visible: visible)
        }
        return BarLayout(entries: entries)
    }
    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: Self.storageKey) }
    }
}

// The center stays at width/2 even when the right controls are wider than the apps.
// Overfull custom configurations scroll within their own band, never cover neighbours.
struct BarGeometry {
    let left: CGRect, center: CGRect, right: CGRect
    init(width: CGFloat, height: CGFloat, centerWidth: CGFloat, gap: CGFloat = 8) {
        let width = max(0, width)
        let middle = min(max(0, centerWidth), width)
        let side = max(0, (width - middle) / 2 - (middle > 0 ? gap : 0))
        left = CGRect(x: 0, y: 0, width: side, height: height)
        center = CGRect(x: (width - middle) / 2, y: 0, width: middle, height: height)
        right = CGRect(x: width - side, y: 0, width: side, height: height)
    }
}
