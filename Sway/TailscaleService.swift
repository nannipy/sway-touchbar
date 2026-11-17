import AppKit

enum TailscaleFailure: Equatable {
    case settings, accessDenied, login, service, timeout, unknown
    static func classify(_ text: String) -> Self {
        let text = text.lowercased()
        if text.contains("non-default") || text.contains("changing settings") { return .settings }
        if text.contains("permission denied") || text.contains("access denied") || text.contains("not authorized") { return .accessDenied }
        if text.contains("not logged") || text.contains("needs login") || text.contains("logged out") { return .login }
        if text.contains("timeout") || text.contains("timed out") || text.contains("deadline exceeded") { return .timeout }
        if text.contains("failed to connect") || text.contains("tailscaled") || text.contains("failed to load preferences") { return .service }
        return .unknown
    }
    var message: String {
        switch self {
        case .settings: return "Tailscale: conferma le impostazioni nell’app"
        case .accessDenied: return "Tailscale: accesso negato alla CLI"
        case .login: return "Tailscale: accedi dall’app"
        case .service: return "Tailscale: servizio locale non disponibile"
        case .timeout: return "Tailscale: connessione scaduta, controlla la rete"
        case .unknown: return "Tailscale: comando fallito, controlla l’app"
        }
    }
}
struct TailscaleCommandResult {
    let succeeded: Bool
    let output: Data
    let failure: TailscaleFailure?
    init(succeeded: Bool, output: Data, failure: TailscaleFailure? = nil) {
        self.succeeded = succeeded; self.output = output; self.failure = failure
    }
}
protocol TailscaleCommandRunning {
    func run(executable: URL, arguments: [String], completion: @escaping (TailscaleCommandResult) -> Void)
}
private final class TailscaleErrorCapture {
    private let lock = NSLock()
    private var failure: TailscaleFailure = .unknown
    private var expired = false
    func drain(_ handle: FileHandle) {
        var prefix = Data()
        while let chunk = try? handle.read(upToCount: 4096), !chunk.isEmpty {
            if prefix.count < 8192 { prefix.append(chunk.prefix(8192 - prefix.count)) }
        }
        let category = TailscaleFailure.classify(String(data: prefix, encoding: .utf8) ?? "")
        lock.lock(); failure = category; lock.unlock()
    }
    func markTimeout() { lock.lock(); expired = true; lock.unlock() }
    var category: TailscaleFailure {
        lock.lock(); defer { lock.unlock() }
        return expired ? .timeout : failure
    }
}
final class TailscaleCommandRunner: TailscaleCommandRunning {
    func run(executable: URL, arguments: [String], completion: @escaping (TailscaleCommandResult) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let process = Process(), pipe = Pipe(), errors = Pipe()
            let capture = TailscaleErrorCapture(), errorRead = DispatchGroup()
            process.executableURL = executable
            process.arguments = arguments
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = pipe
            let statusQuery = arguments.first == "status"
            // Drain stderr concurrently; keep only a bounded in-memory classification.
            process.standardError = errors
            do { try process.run() }
            catch { DispatchQueue.main.async { completion(.init(succeeded: false, output: Data(), failure: .service)) }; return }
            errorRead.enter()
            DispatchQueue.global(qos: .utility).async {
                capture.drain(errors.fileHandleForReading); errorRead.leave()
            }
            let timeout = DispatchWorkItem {
                guard process.isRunning else { return }
                capture.markTimeout()
                process.terminate()
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1) {
                    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                }
            }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10, execute: timeout)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit(); timeout.cancel(); errorRead.wait()
            let success = process.terminationReason == .exit && process.terminationStatus == 0
            let stderrCategory = capture.category
            let category = stderrCategory == .unknown ? TailscaleFailure.classify(String(data: data.prefix(8192), encoding: .utf8) ?? "") : stderrCategory
            let result = TailscaleCommandResult(succeeded: success, output: statusQuery && success ? data : Data(), failure: success ? nil : category)
            DispatchQueue.main.async { completion(result) }
        }
    }
}

final class TailscaleService {
    enum State: Equatable {
        case unknown, connected, disconnected, starting, needsLogin, unavailable
        static func decode(_ data: Data) -> State {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let backend = json["BackendState"] as? String else { return .unknown }
            switch backend {
            case "Running": return .connected
            case "Stopped": return .disconnected
            case "Starting": return .starting
            case "NeedsLogin", "NeedsMachineAuth": return .needsLogin
            default: return .unknown
            }
        }
    }
    private let executable: URL?
    private let runner: TailscaleCommandRunning
    private var timer: Timer?
    private var toggleGeneration: UInt = 0
    private(set) var state: State = .unknown
    private(set) var busy = false
    private(set) var lastFailure: TailscaleFailure?
    var changed: (() -> Void)?
    var message: ((String) -> Void)?
    init(executable: URL? = TailscaleService.locateCLI(), runner: TailscaleCommandRunning = TailscaleCommandRunner()) {
        self.executable = executable; self.runner = runner
        if executable == nil { state = .unavailable }
    }
    static func locateCLI() -> URL? {
        ["/Applications/Tailscale.app/Contents/MacOS/Tailscale", "/opt/homebrew/bin/tailscale", "/usr/local/bin/tailscale"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }.map { URL(fileURLWithPath: $0) }
    }
    func startMonitoring() {
        stopMonitoring(); refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 3
    }
    func stopMonitoring() { timer?.invalidate(); timer = nil; toggleGeneration &+= 1 }
    deinit { timer?.invalidate() }
    func refresh(completion: (() -> Void)? = nil) {
        guard !busy else { completion?(); return }
        guard let executable else { state = .unavailable; changed?(); completion?(); return }
        busy = true; changed?()
        runner.run(executable: executable, arguments: ["status", "--json", "--peers=false"]) { [weak self] result in
            guard let self else { return }
            self.lastFailure = result.failure
            self.state = result.succeeded ? State.decode(result.output) : .unknown
            if result.succeeded && self.state == .unknown && (try? JSONSerialization.jsonObject(with: result.output)) == nil {
                self.lastFailure = TailscaleFailure.classify(String(data: result.output.prefix(8192), encoding: .utf8) ?? "")
            }
            self.busy = false; self.changed?(); completion?()
        }
    }
    func toggle() {
        guard !busy else { return }
        // Reconcile before choosing up/down: another client may have changed state.
        let generation = toggleGeneration
        refresh { [weak self] in
            guard let self, self.toggleGeneration == generation else { return }
            self.toggleKnownState()
        }
    }
    private func toggleKnownState() {
        guard !busy, let executable else { message?("Tailscale non disponibile"); return }
        guard state == .connected || state == .disconnected else {
            message?(state == .needsLogin ? "Accedi dall’app Tailscale" : (lastFailure?.message ?? "Controlla lo stato nell’app Tailscale"))
            if state == .needsLogin {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Tailscale.app"), configuration: .init(), completionHandler: nil)
            }
            return
        }
        let connect = state == .disconnected
        busy = true; changed?()
        runner.run(executable: executable, arguments: connect ? ["up"] : ["down"]) { [weak self] result in
            guard let self else { return }
            self.busy = false
            self.refresh { [weak self] in
                guard let self else { return }
                let confirmed = connect ? self.state == .connected : self.state == .disconnected
                if confirmed { self.message?(connect ? "Tailscale connesso" : "Tailscale disconnesso") }
                else if self.state == .needsLogin { self.message?(TailscaleFailure.login.message) }
                else if self.state == .starting { self.message?("Tailscale: connessione in corso") }
                else { self.message?((result.failure ?? .unknown).message) }
            }
        }
    }
}

func tailscaleIcon(connected: Bool, busy: Bool) -> NSImage {
    NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        for row in 0..<3 {
            for column in 0..<3 {
                let lit = connected && (row == 1 || (row == 2 && column == 1))
                NSColor(white: lit ? 1 : (busy ? 0.5 : 0.28), alpha: 1).setFill()
                NSBezierPath(ovalIn: NSRect(x: CGFloat(1 + column * 6), y: CGFloat(13 - row * 6), width: 3.5, height: 3.5)).fill()
            }
        }
        return true
    }
}
