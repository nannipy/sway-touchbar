import AppKit

@main struct HUDProbe {
    static func windows() -> [[String: Any]] {
        CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    }
    static func modernBanners() -> [[String: Any]] {
        guard let pid = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.controlcenter").first?.processIdentifier else { return [] }
        return windows().filter { window in
            guard (window[kCGWindowOwnerPID as String] as? Int32) == pid,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let height = bounds["Height"] as? Double, let width = bounds["Width"] as? Double else { return false }
            return height > 30 && width > 100
        }
    }
    static func legacyVisible() -> Bool {
        windows().contains { ($0[kCGWindowOwnerName as String] as? String)?.localizedCaseInsensitiveContains("OSDUIHelper") == true }
    }
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let display = NSScreen.screens.compactMap { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 }.first { CGDisplayIsBuiltin($0) != 0 } ?? CGMainDisplayID()
        let audio = AudioService(), brightness = BrightnessService(), keyboard = KeyboardBrightnessService()
        // Let unrelated native indicators from earlier user input finish first.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
        for (kind, value) in [(HUDKind.brightness, brightness.value), (.volume, audio.volume), (.keyboard, keyboard.value)] {
            guard let value else { continue }
            let accepted = SwayShowSystemHUD(kind.rawValue, display, value, false)
            print("HUD", kind, "request dispatched:", accepted)
            guard accepted else { exit(1) }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
            if #available(macOS 26, *) {
                let banners = modernBanners()
                guard !banners.isEmpty, !legacyVisible() else {
                    fputs("Expected modern Control Center banner; legacy OSD must be absent\n", stderr); exit(1)
                }
                if let id = banners.first?[kCGWindowNumber as String] as? Int {
                    let capture = Process()
                    capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                    capture.arguments = ["-x", "-o", "-l", String(id), "build/hud-modern-\(kind).png"]
                    do { try capture.run(); capture.waitUntilExit() } catch { print("Screenshot unavailable") }
                }
                let deadline = Date(timeIntervalSinceNow: 8)
                while !modernBanners().isEmpty && Date() < deadline {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
                }
                guard modernBanners().isEmpty else {
                    fputs("Native banner did not fade within 8 seconds (system changes can prolong visibility)\n", stderr); exit(1)
                }
                print("PASS modern Control Center banner and native fade:", kind)
            } else {
                guard legacyVisible() else { exit(1) }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
                guard !legacyVisible() else { exit(1) }
            }
        }
    }
}
