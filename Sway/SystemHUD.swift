import AppKit

final class SystemHUD {
    private var scheduled: DispatchWorkItem?
    private var latest: (HUDKind, Double, Bool)?
    private var lastSent: TimeInterval = -.infinity
    private(set) var available = true

    func show(_ kind: HUDKind, value: Double, locked: Bool = false) {
        guard value.isFinite else { return }
        latest = (kind, bounded(value), locked)
        scheduled?.cancel()
        let remaining = max(0, 0.05 - (ProcessInfo.processInfo.systemUptime - lastSent))
        if remaining == 0 { sendLatest() }
        else {
            let work = DispatchWorkItem { [weak self] in self?.sendLatest() }
            scheduled = work
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: work)
        }
    }
    private func sendLatest() {
        guard let (kind, value, locked) = latest else { return }
        latest = nil; scheduled = nil
        lastSent = ProcessInfo.processInfo.systemUptime
        let screen = NSScreen.screens.first { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 else { return false }
            return CGDisplayIsBuiltin(id) != 0
        } ?? NSScreen.main
        let display = screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 ?? CGMainDisplayID()
        available = SwayShowSystemHUD(kind.rawValue, display, value, locked)
    }
    func cancel() { scheduled?.cancel(); scheduled = nil; latest = nil }
    deinit { scheduled?.cancel() }
}
