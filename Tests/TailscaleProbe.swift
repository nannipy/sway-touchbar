import AppKit
@main struct TailscaleProbe {
    static func main() {
        let service = TailscaleService()
        var done = false
        service.refresh { print("Tailscale production status:", service.state, "busy:", service.busy); done = true }
        for _ in 0..<48 {
            if done { break }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        }
        guard done && (service.state == .connected || service.state == .disconnected || service.state == .needsLogin || service.state == .starting) else { exit(1) }
    }
}
