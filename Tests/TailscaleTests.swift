import Foundation
import AppKit
final class FakeTailscaleRunner: TailscaleCommandRunning {
    var calls: [[String]] = []
    var pending: [(TailscaleCommandResult) -> Void] = []
    func run(executable: URL, arguments: [String], completion: @escaping (TailscaleCommandResult) -> Void) {
        calls.append(arguments); pending.append(completion)
    }
    func finish(_ state: String? = nil, success: Bool = true, failure: TailscaleFailure? = nil) {
        let result = TailscaleCommandResult(succeeded: success, output: state.map { Data("{\"BackendState\":\"\($0)\"}".utf8) } ?? Data(), failure: failure)
        pending.removeFirst()(result)
    }
}
@main struct TailscaleTests {
    static func main() {
        assert(TailscaleService.State.decode(Data("{\"BackendState\":\"Running\"}".utf8)) == .connected)
        assert(TailscaleService.State.decode(Data("{\"BackendState\":\"Stopped\"}".utf8)) == .disconnected)
        assert(TailscaleService.State.decode(Data("{\"BackendState\":\"NeedsLogin\"}".utf8)) == .needsLogin)
        assert(TailscaleService.State.decode(Data("invalid".utf8)) == .unknown)
        assert(TailscaleFailure.classify("requires all non-default flags") == .settings)
        assert(TailscaleFailure.classify("permission denied") == .accessDenied)
        assert(TailscaleFailure.classify("not logged in") == .login)
        assert(TailscaleFailure.classify("deadline exceeded") == .timeout)
        assert(TailscaleFailure.classify("failed to load preferences") == .service)
        let runner = FakeTailscaleRunner()
        let service = TailscaleService(executable: URL(fileURLWithPath: "/fake/tailscale"), runner: runner)
        service.toggle(); service.toggle()
        assert(service.busy && runner.calls.count == 1)
        runner.finish("Stopped")
        assert(runner.calls.last == ["up"])
        assert(service.state == .disconnected && service.busy)
        runner.finish()
        runner.finish("Running")
        assert(service.state == .connected && !service.busy)
        service.toggle()
        runner.finish("Running")
        assert(runner.calls.last == ["down"])
        runner.finish()
        runner.finish("Stopped")
        assert(service.state == .disconnected)
        service.toggle()
        runner.finish("Stopped")
        runner.finish(success: false)
        runner.finish("Stopped")
        assert(service.state == .disconnected && !service.busy)
        let count = runner.calls.count
        service.toggle(); runner.finish("Starting")
        assert(runner.calls.count == count + 1 && service.state == .starting)
        service.toggle(); service.stopMonitoring(); runner.finish("Stopped")
        assert(!service.busy && runner.pending.isEmpty) // Pause cancels preflight, not a live VPN.
        var message = ""
        service.message = { message = $0 }
        let beforeFailure = runner.calls.count
        service.toggle(); runner.finish(success: false, failure: .accessDenied)
        assert(service.lastFailure == .accessDenied && message.contains("accesso negato"))
        assert(runner.calls.count == beforeFailure + 1) // No up/down when preflight fails.
        assert(runner.calls.allSatisfy { !$0.contains("--reset") })
        assert(tailscaleIcon(connected: true, busy: false).tiffRepresentation != nil)
        assert(tailscaleIcon(connected: false, busy: false).tiffRepresentation != nil)
        let logo = NSBitmapImageRep(data: tailscaleIcon(connected: true, busy: false).tiffRepresentation!)!
        for row in 0..<3 {
            for column in 0..<3 {
                let x = (column * 6 + 3) * logo.pixelsWide / 18
                let y = (row * 6 + 3) * logo.pixelsHigh / 18
                let lit = logo.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!.redComponent > 0.8
                assert(lit == (row == 1 || (row == 2 && column == 1)), "T must use middle row and one dot below")
            }
        }
        print("Tailscale state, confirmed toggle, busy guard and logo tests passed (no VPN changes)")
    }
}
