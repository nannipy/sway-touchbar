import AppKit
final class Fixture: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    let result = URL(fileURLWithPath: CommandLine.arguments.last!)
    func applicationDidFinishLaunching(_ note: Notification) {
        try? "launched without windows".write(to: result, atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { NSApp.terminate(nil) }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 80), styleMask: [.titled], backing: .buffered, defer: false)
        window?.title = "Sway — reopen test"
        window?.makeKeyAndOrderFront(nil)
        try? "reopened; previously visible=\(hasVisibleWindows); window created=\(window?.isVisible == true)".write(to: result, atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
        return true
    }
}
let app = NSApplication.shared
let fixture = Fixture()
app.delegate = fixture
app.run()
