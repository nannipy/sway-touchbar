import AppKit
@main struct ReopenProbe {
    static func main() {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("build")
        let fixture = root.appendingPathComponent("ReopenFixture.app")
        let result = root.appendingPathComponent("reopen-result.txt")
        try? FileManager.default.removeItem(at: result)
        var failure: Error?
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = [result.path]
        config.activates = true
        config.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: fixture, configuration: config) { _, error in
            if let error { failure = error; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let reopen = NSWorkspace.OpenConfiguration()
                reopen.activates = true
                reopen.createsNewApplicationInstance = false
                NSWorkspace.shared.openApplication(at: fixture, configuration: reopen) { _, error in failure = error }
            }
        }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 4))
        if let failure { fatalError("Reopen failed: \(failure)") }
        let output = (try? String(contentsOf: result, encoding: .utf8)) ?? "missing result"
        print(output)
        guard output.contains("previously visible=false; window created=true") else { exit(1) }
    }
}
