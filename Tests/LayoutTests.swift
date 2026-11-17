import Foundation

@main struct LayoutTests {
    static func main() {
        let initial = BarLayout()
        assert(initial.widgets(in: .left) == [.apps])
        assert(initial.widgets(in: .center) == [.date, .battery, .clock])
        assert(initial.widgets(in: .right) == [.light, .keyboard, .audio, .tailscale])
        var custom = initial
        custom.entries[0].zone = .right
        custom.entries[1].visible = false
        custom.move(from: 7, to: 0)
        assert(custom.widgets(in: .right) == [.tailscale, .apps, .light, .keyboard, .audio])
        assert(custom.widgets(in: .center) == [.battery, .clock])
        custom.move(from: 0, to: custom.entries.count)
        assert(custom.entries.last?.widget == .tailscale)
        let suite = "dev.sway.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        custom.save(to: defaults)
        assert(BarLayout.load(from: defaults) == custom)
        defaults.set(Data("[{\"widget\":\"future\",\"zone\":\"left\",\"visible\":true},{\"widget\":\"audio\",\"zone\":\"left\",\"visible\":false},{\"widget\":\"audio\",\"zone\":\"right\",\"visible\":true}]".utf8), forKey: BarLayout.storageKey)
        let migrated = BarLayout.load(from: defaults)
        assert(migrated.entries.count == BarWidget.allCases.count)
        assert(migrated.entries.first == BarEntry(widget: .audio, zone: .left, visible: false))
        defaults.set(Data("invalid".utf8), forKey: BarLayout.storageKey)
        assert(BarLayout.load(from: defaults) == initial)
        for width: CGFloat in [0, 100, 800, 1004, 1085] {
            for centerWidth: CGFloat in [0, 190, 2000] {
                let geometry = BarGeometry(width: width, height: 30, centerWidth: centerWidth)
                assert(abs(geometry.center.midX - width / 2) < 0.001)
                assert(geometry.left.maxX <= geometry.center.minX)
                assert(geometry.center.maxX <= geometry.right.minX)
                assert(geometry.right.maxX <= width)
            }
        }
        print("Layout defaults, reorder, persistence, migration and centering tests passed")
    }
}
