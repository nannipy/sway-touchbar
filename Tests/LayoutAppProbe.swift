import AppKit

@main struct LayoutAppProbe {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = SwayApp()
        // Use defaults only in this process; never overwrite the user's saved arrangement.
        delegate.layout = BarLayout()
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
        let root = delegate.barContent
        // Worst-case spacing fixture, without changing system battery or app focus.
        delegate.batteryLabel.update(percent: 100, charging: true)
        (delegate.apps.arrangedSubviews.first as? AppButton)?.isForeground = true
        root.needsLayout = true
        root.layoutSubtreeIfNeeded()
        fputs("Runtime Touch Bar bounds: \(root.bounds)\n", stderr)
        assert(abs(root.bounds.width - root.window!.contentView!.bounds.width) < 0.5, "Bar wider than actual Touch Bar")
        assert(root.bounds.width > 500, "Touch Bar content unexpectedly narrow")
        for control in [delegate.light!, delegate.keyboardLight!, delegate.volume!, delegate.tailscaleButton] as [NSView] {
            var ancestor = control.superview
            while let view = ancestor {
                assert(!(view is NSScrollView), "A pan recognizer must not wrap direct-touch controls")
                ancestor = view.superview
            }
        }
        let center = root.subviews[1]
        assert(abs(center.frame.midX - root.bounds.midX) < 0.5)
        let leftScroll = root.subviews[0] as! ControlBandView
        let rightScroll = root.subviews[2] as! ControlBandView
        assert(leftScroll.bounds.width > 230, "Apps still constrained to old width")
        assert(abs(rightScroll.frame.maxX - root.bounds.maxX) < 0.5)
        assert(center.frame.maxX <= rightScroll.frame.minX)
        assert(leftScroll.frame.maxX <= center.frame.minX)
        if let rep = root.bitmapImageRepForCachingDisplay(in: root.bounds) {
            root.cacheDisplay(in: root.bounds, to: rep)
            try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "build/layout-bar.png"))
        }
        let touchBarCapture = Process()
        touchBarCapture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        touchBarCapture.arguments = ["-x", "-b", "build/layout-spacing-native.png"]
        do { try touchBarCapture.run(); touchBarCapture.waitUntilExit() } catch { print("Touch Bar capture unavailable") }
        let appWidth = leftScroll.frame.width
        delegate.showSettings()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        guard let window = app.windows.first(where: { $0.title == "Personalizza Sway" }), let content = window.contentView else { fatalError("Settings window missing") }
        let table = content.subviews.compactMap { ($0 as? NSScrollView)?.documentView as? NSTableView }.first!
        assert(table.numberOfRows == BarWidget.allCases.count)
        assert(table.tableColumns.count == 3)
        assert(abs(delegate.dateLabel.frame.midY - root.bounds.midY) < 0.5)
        assert(abs(delegate.clockLabel.frame.midY - delegate.batteryLabel.frame.midY) < 0.5)
        content.layoutSubtreeIfNeeded()
        if let rep = content.bitmapImageRepForCachingDisplay(in: content.bounds) {
            content.cacheDisplay(in: content.bounds, to: rep)
            try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "build/layout-settings.png"))
        }
        // Exercise all-hidden and dense configurations without persisting or touching hardware.
        delegate.layout.entries = delegate.layout.entries.map { var row = $0; row.visible = false; return row }
        delegate.applyLayout(); root.layoutSubtreeIfNeeded()
        assert(root.subviews.allSatisfy { $0.frame.width == 0 })
        delegate.layout.entries = BarLayout.defaults.map { var row = $0; row.zone = .right; return row }
        delegate.applyLayout(); root.layoutSubtreeIfNeeded()
        assert(root.subviews[2].frame.maxX <= root.bounds.maxX)
        // Capture the actual native window where Screen Recording is already permitted.
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), "build/layout-settings-window.png"]
        try? capture.run(); capture.waitUntilExit()
        window.close()
        assert(!delegate.applicationShouldTerminateAfterLastWindowClosed(app))
        assert(delegate.applicationShouldHandleReopen(app, hasVisibleWindows: false))
        assert(window.isVisible, "Opening app again must reopen settings")
        let settingsCount = app.windows.filter { $0.title == "Personalizza Sway" }.count
        assert(settingsCount == 1, "Reopening must reuse the same settings window")
        window.close()
        delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
        print("PASS native bar: width \(root.bounds.width), apps \(appWidth); centered band, settings, hidden/dense layouts")
    }
}
