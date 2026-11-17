import AppKit
import IOKit.ps
import os

// Opt-in, local-only input diagnostics. No key events or account/network data.
enum ControlDiagnostics {
    static let enabled = CommandLine.arguments.contains("--diagnose-touch")
    static let logger = Logger(subsystem: "dev.sway.touchbar", category: "controls")
    static func record(_ text: String) {
        guard enabled else { return }
        logger.info("\(text, privacy: .public)")
    }
    static func event(_ tag: String, _ event: NSEvent, in view: NSView) {
        guard enabled else { return }
        let touches = event.touches(matching: .any, in: nil).map { touch in
            "phase=\(touch.phase.rawValue) type=\(touch.type.rawValue) x=\(Int(touch.location(in: view).x))"
        }.joined(separator: ";")
        record("\(tag) event=\(event.type.rawValue) touches=[\(touches)]")
    }
}
final class TracedTailscaleButton: NSButton {
    override func touchesBegan(with event: NSEvent) { ControlDiagnostics.event("vpn.begin", event, in: self); super.touchesBegan(with: event) }
    override func touchesEnded(with event: NSEvent) { ControlDiagnostics.event("vpn.end", event, in: self); super.touchesEnded(with: event) }
    override func mouseDown(with event: NSEvent) { ControlDiagnostics.record("vpn.mouseDown"); super.mouseDown(with: event) }
}

// Native Pock-style segments. Touch Bar delivers direct touches, not mouse events.
final class AdjustmentView: NSSegmentedControl {
    let read: () -> Double?
    let write: (Double) -> Void
    let mute: (() -> Void)?
    private var gesture: Adjustment?
    private var swiping = false
    private var trackedTouch: NSTouch?
    private var mouseTracking = false
    private var initialSegment = 0
    private var pressedSegment: Int?
    private var releaseGeneration = 0
    var feedback: (() -> Void)?
    private let segmentWidth: CGFloat = 44
    private let level = NSSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
    init(symbol: String, read: @escaping () -> Double?, write: @escaping (Double) -> Void, mute: (() -> Void)? = nil) {
        self.read = read; self.write = write; self.mute = mute
        super.init(frame: .zero)
        trackingMode = .momentary
        segmentCount = mute == nil ? 2 : 3
        let names: [NSImage.Name] = mute == nil
            ? [NSImage.Name("sway.brightness.down"), NSImage.Name("sway.brightness.up")]
            : [NSImage.touchBarVolumeDownTemplateName, NSImage.touchBarAudioOutputMuteTemplateName, NSImage.touchBarVolumeUpTemplateName]
        let keyboard = symbol == "keyboard"
        let labels = mute == nil ? (keyboard ? ["Diminuisci luce tastiera", "Aumenta luce tastiera"] : ["Diminuisci luminosità", "Aumenta luminosità"]) : ["Diminuisci volume", "Muto", "Aumenta volume"]
        for index in 0..<segmentCount {
            let image = mute == nil
                ? NSImage(systemSymbolName: keyboard ? (index == 0 ? "light.min" : "light.max") : (index == 0 ? "sun.min.fill" : "sun.max.fill"), accessibilityDescription: labels[index])
                : NSImage(named: names[index])
            let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let configured = image?.withSymbolConfiguration(configuration) ?? image
            if let compact = configured?.copy() as? NSImage {
                let longest = max(compact.size.width, compact.size.height)
                if longest > 0 { compact.size = NSSize(width: compact.size.width * 16 / longest, height: compact.size.height * 16 / longest) }
                setImage(compact, forSegment: index)
            }
            setWidth(segmentWidth, forSegment: index)
            setToolTip(labels[index], forSegment: index)
        }
        controlSize = .large
        widthAnchor.constraint(equalToConstant: CGFloat(segmentCount) * segmentWidth + 8).isActive = true
        allowedTouchTypes = [.direct]
        target = self; action = #selector(tapped)
        // The slider is presentation only: the originating control keeps the drag.
        level.target = nil; level.action = nil
        level.setAccessibilityElement(false)
        level.setAccessibilityHidden(true)
        level.refusesFirstResponder = true
        level.isHidden = true
        addSubview(level)
        setAccessibilityLabel(keyboard ? "Luce tastiera" : (mute == nil ? "Luminosità" : "Volume"))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        if newSuperview == nil { cancelInteraction() }
        super.viewWillMove(toSuperview: newSuperview)
    }
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { cancelInteraction() }
        super.viewWillMove(toWindow: newWindow)
    }
    func cancelInteraction() {
        releaseGeneration += 1
        resetGesture()
        pressedSegment = nil
        needsDisplay = true
    }
    override func layout() {
        super.layout()
        level.frame = bounds.insetBy(dx: 8, dy: 3)
    }
    @objc private func tapped() {
        guard !swiping, let value = read(), selectedSegment >= 0 else { return }
        applyTap(selectedSegment, value: value)
    }
    private func applyTap(_ segment: Int, value: Double) {
        if segment == 0 { write(bounded(value - 1 / 16)) }
        else if segment == segmentCount - 1 { write(bounded(value + 1 / 16)) }
        else { mute?() }
        feedback?()
    }
    override func draw(_ dirtyRect: NSRect) {
        if level.isHidden {
            super.draw(dirtyRect)
            if let pressedSegment {
                let width = bounds.width / CGFloat(segmentCount)
                let rect = NSRect(x: CGFloat(pressedSegment) * width + 2, y: 1, width: width - 4, height: bounds.height - 2)
                NSColor.white.withAlphaComponent(0.3).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
            }
        }
        else { NSColor.black.setFill(); dirtyRect.fill() }
    }
    // AppKit can deliver Touch Bar input through either direct NSTouch events or
    // mouse tracking. Never enter NSSegmentedCell's blocking mouseDown tracker:
    // it consumes drag events before our slider can see them.
    override func mouseDown(with event: NSEvent) {
        guard trackedTouch == nil, !mouseTracking else { return }
        mouseTracking = true
        beginInteraction(at: convert(event.locationInWindow, from: nil).x)
    }
    override func mouseDragged(with event: NSEvent) {
        guard mouseTracking else { return }
        moveInteraction(to: convert(event.locationInWindow, from: nil).x)
    }
    override func mouseUp(with event: NSEvent) {
        guard mouseTracking else { return }
        finishInteraction(at: convert(event.locationInWindow, from: nil).x)
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Revealing the visual slider must not transfer the gesture to a child.
        super.hitTest(point) == nil ? nil : self
    }
    override func touchesBegan(with event: NSEvent) {
        ControlDiagnostics.event("adjust.begin", event, in: self)
        guard !mouseTracking, trackedTouch == nil,
              let touch = event.touches(matching: .began, in: self).first else { return }
        trackedTouch = touch
        beginInteraction(at: touch.location(in: self).x)
    }
    override func touchesMoved(with event: NSEvent) {
        ControlDiagnostics.event("adjust.move", event, in: self)
        guard let trackedTouch,
              let touch = event.touches(matching: .any, in: self).first(where: { $0.identity.isEqual(trackedTouch.identity) }) else { return }
        moveInteraction(to: touch.location(in: self).x)
    }
    override func touchesEnded(with event: NSEvent) {
        ControlDiagnostics.event("adjust.end", event, in: self)
        guard let trackedTouch,
              let touch = event.touches(matching: .any, in: self).first(where: { $0.identity.isEqual(trackedTouch.identity) && $0.phase == .ended }) else { return }
        finishInteraction(at: touch.location(in: self).x)
    }
    override func touchesCancelled(with event: NSEvent) {
        ControlDiagnostics.event("adjust.cancel", event, in: self)
        guard trackedTouch != nil else { return }
        resetGesture()
    }
    private func beginInteraction(at x: CGFloat) {
        releaseGeneration += 1
        gesture = read().map { Adjustment(initial: $0, origin: x) }
        initialSegment = min(segmentCount - 1, max(0, Int(x / max(bounds.width, 1) * CGFloat(segmentCount))))
        pressedSegment = initialSegment
        setSelected(true, forSegment: initialSegment)
        swiping = false
        needsDisplay = true
        displayIfNeeded()
    }
    private func moveInteraction(to x: CGFloat) {
        guard let gesture else { return }
        swiping = swiping || gesture.isSwipe(at: x)
        guard swiping else { return }
        pressedSegment = nil
        level.doubleValue = gesture.value(at: x, width: bounds.width)
        level.isHidden = false
        write(level.doubleValue)
        feedback?()
        needsDisplay = true
    }
    private func finishInteraction(at x: CGFloat) {
        if let gesture {
            // Also recognize a swipe when AppKit coalesces every intermediate move.
            if swiping || gesture.isSwipe(at: x) {
                write(gesture.value(at: x, width: bounds.width)); feedback?()
            } else { applyTap(initialSegment, value: gesture.initial) }
        }
        resetGesture()
    }
    private func resetGesture() {
        gesture = nil; trackedTouch = nil; mouseTracking = false; swiping = false; level.isHidden = true
        for index in 0..<segmentCount { setSelected(false, forSegment: index) }
        needsDisplay = true
        let generation = releaseGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self, self.trackedTouch == nil, !self.mouseTracking, self.releaseGeneration == generation else { return }
            self.pressedSegment = nil; self.needsDisplay = true
        }
    }
}

final class SwayApp: NSObject, NSApplicationDelegate, NSTouchBarDelegate {
    let audio = AudioService(), brightness = BrightnessService(), keyboardBrightness = KeyboardBrightnessService()
    let bar = NSTouchBar()
    let hud = SystemHUD()
    let tailscale = TailscaleService()
    let tailscaleButton = TracedTailscaleButton()
    var tailscaleLastMessage = "Nessuna operazione di connessione eseguita in questa sessione."
    var status: NSStatusItem!
    var timer: Timer?
    var lastAppState: String = ""
    var powerSource: CFRunLoopSource?
    var observers: [NSObjectProtocol] = []
    let apps = NSStackView()
    let dateLabel = NSTextField(labelWithString: "")
    let batteryLabel = BatteryView(frame: .zero)
    let clockLabel = NSTextField(labelWithString: "")
    lazy var barContent = BarContentView(apps: apps)
    var layout = BarLayout.load()
    var settings: LayoutSettings?
    var feedbackMenuItem: NSMenuItem!
    var lastFeedback = "Nessuna azione recente"
    var paused = false
    var preview: NSWindow?
    var volume: AdjustmentView!
    var light: AdjustmentView!
    var keyboardLight: AdjustmentView!
    var automaticKeyboardItem: NSMenuItem!
    let formatter = DateFormatter()
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationMenu()
        formatter.dateFormat = "d MMM  HH:mm"
        volume = AdjustmentView(symbol: "speaker.wave.2", read: { [weak self] in self?.audio.volume }, write: { [weak self] in self?.adjustVolume($0) }, mute: { [weak self] in self?.toggleMuteWithHUD() })
        light = AdjustmentView(symbol: "sun.max", read: { [weak self] in self?.brightness.value }, write: { [weak self] in self?.adjustDisplay($0) })
        keyboardLight = AdjustmentView(symbol: "keyboard", read: { [weak self] in self?.keyboardBrightness.value }, write: { [weak self] in self?.adjustKeyboard($0) })
        volume.feedback = { [weak self] in guard let self else { return }; self.showFeedback(self.audio.lastError ?? "Volume \(Int((self.audio.volume ?? 0) * 100))%") }
        light.feedback = { [weak self] in guard let self else { return }; self.showFeedback(self.brightness.lastError ?? "Display \(Int((self.brightness.value ?? 0) * 100))%") }
        keyboardLight.feedback = { [weak self] in guard let self else { return }; self.showFeedback(self.keyboardBrightness.lastError ?? "Tastiera \(Int((self.keyboardBrightness.value ?? 0) * 100))%") }
        tailscaleButton.bezelStyle = .rounded
        tailscaleButton.target = self; tailscaleButton.action = #selector(toggleTailscale)
        tailscaleButton.imagePosition = .imageOnly
        tailscaleButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        tailscaleButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
        tailscale.changed = { [weak self] in self?.refreshTailscaleButton() }
        tailscale.message = { [weak self] text in
            self?.tailscaleLastMessage = text
            self?.showFeedback(text)
        }
        tailscale.startMonitoring()
        audio.changed = { [weak self] in self?.volume.needsDisplay = true }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "Sway"
        let menu = NSMenu()
        for (title, action) in [("Mostra Sway", #selector(show)), ("Sospendi / riprendi", #selector(toggle)), ("Personalizza Sway…", #selector(showSettings)), ("Anteprima e stato…", #selector(showPreview)), ("Esci da Sway", #selector(quit))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: ""); item.target = self
        }
        automaticKeyboardItem = NSMenuItem(title: "Luminosità tastiera automatica", action: #selector(toggleKeyboardAutomatic), keyEquivalent: "")
        automaticKeyboardItem.target = self
        automaticKeyboardItem.toolTip = "Disattiva per regolare manualmente la luce quando il sensore ambientale la limita."
        automaticKeyboardItem.state = keyboardBrightness.automatic ? .on : .off
        menu.insertItem(automaticKeyboardItem, at: 3)
        let tailscaleStatus = NSMenuItem(title: "Stato Tailscale…", action: #selector(showTailscaleStatus), keyEquivalent: "")
        tailscaleStatus.target = self
        menu.insertItem(tailscaleStatus, at: 4)
        feedbackMenuItem = NSMenuItem(title: "Nessuna azione recente", action: nil, keyEquivalent: "")
        menu.insertItem(feedbackMenuItem, at: menu.items.count - 1)
        status.menu = menu
        apps.orientation = .horizontal; apps.spacing = 4; apps.alignment = .centerY
        for label in [dateLabel, clockLabel] {
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            label.textColor = .white
            label.alignment = .center
            label.maximumNumberOfLines = 1
            label.lineBreakMode = .byClipping
        }
        bar.delegate = self
        bar.defaultItemIdentifiers = [.init("sway.content")]
        bar.principalItemIdentifier = .init("sway.content")
        applyLayout()
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification, NSWorkspace.didActivateApplicationNotification, NSWorkspace.didWakeNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.refreshApps(); self?.refresh(); })
        }
        for name in [NSLocale.currentLocaleDidChangeNotification, NSNotification.Name.NSSystemClockDidChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.refresh() })
        }
        powerSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }; Unmanaged<SwayApp>.fromOpaque(context).takeUnretainedValue().refresh()
        }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue()
        if let powerSource { CFRunLoopAddSource(CFRunLoopGetMain(), powerSource, .defaultMode) }
        refreshApps(); refresh(); show(); showSettings()
    }
    func configureApplicationMenu() {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu(title: "Sway")
        let about = applicationMenu.addItem(withTitle: "Informazioni su Sway", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        about.target = NSApp
        applicationMenu.addItem(.separator())
        let preferences = applicationMenu.addItem(withTitle: "Personalizza Sway…", action: #selector(showSettings), keyEquivalent: ",")
        preferences.target = self
        applicationMenu.addItem(.separator())
        let hide = applicationMenu.addItem(withTitle: "Nascondi Sway", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hide.target = NSApp
        let quit = applicationMenu.addItem(withTitle: "Esci da Sway", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Finestra")
        windowMenu.addItem(withTitle: "Chiudi finestra", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Contrai", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = windowMenu; menu.addItem(windowItem)
        NSApp.mainMenu = menu; NSApp.windowsMenu = windowMenu
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show(); showSettings()
        return true
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func refresh() {
        let status = batteryStatus()
        formatter.dateFormat = "d MMM"
        dateLabel.stringValue = formatter.string(from: Date())
        formatter.dateFormat = "HH:mm"
        clockLabel.stringValue = formatter.string(from: Date())
        batteryLabel.update(percent: status.percent, charging: status.charging)
        barContent.needsLayout = true
        light.needsDisplay = true; keyboardLight.needsDisplay = true; volume.needsDisplay = true
        timer?.invalidate()
        guard !paused else { return }
        let interval = 60 - Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 1
    }
    func refreshApps() {
        let active = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let running = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        let state = running.map { String($0.processIdentifier) }.sorted().joined(separator: ",") + ":" + String(active ?? 0)
        guard state != lastAppState else { return }
        lastAppState = state
        let existing = apps.arrangedSubviews.compactMap { ($0 as? AppButton)?.app }
        let ordered = existing.filter { app in running.contains { $0.processIdentifier == app.processIdentifier } } + running.filter { app in !existing.contains { $0.processIdentifier == app.processIdentifier } }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
        for view in apps.arrangedSubviews { apps.removeArrangedSubview(view); view.removeFromSuperview() }
        for app in ordered {
            let button = AppButton(app: app)
            button.onError = { [weak self] in self?.showFeedback($0) }
            let foreground = app.processIdentifier == active
            button.isForeground = foreground
            button.focusRingType = .none
            apps.addArrangedSubview(button)
        }
        apps.frame = NSRect(x: 0, y: 0, width: max(36, CGFloat(ordered.count) * 40), height: 30)
    }
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier.rawValue == "sway.content" else { return nil }
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = barContent
        return item
    }
    func applyLayout() {
        barContent.configure(layout, views: [.date: dateLabel, .battery: batteryLabel, .clock: clockLabel,
            .light: light, .keyboard: keyboardLight, .audio: volume, .tailscale: tailscaleButton])
    }
    @objc func showSettings() {
        if settings == nil {
            settings = LayoutSettings(layout: layout) { [weak self] updated in
                guard let self else { return }
                self.layout = updated
                self.applyLayout()
            }
        }
        settings?.show()
    }
    @objc func show() {
        guard !paused else { return }
        if NSTouchBar.responds(to: NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")) {
            NSTouchBar.presentSystemModalTouchBar(bar, placement: 1, systemTrayItemIdentifier: nil)
        }
    }
    @objc func toggle() {
        paused.toggle()
        if paused { volume.cancelInteraction(); light.cancelInteraction(); keyboardLight.cancelInteraction(); dismiss(); timer?.invalidate(); keyboardBrightness.endInteraction(); hud.cancel(); tailscale.stopMonitoring() } else { refresh(); show(); tailscale.startMonitoring() }
    }
    func dismiss() {
        if NSTouchBar.responds(to: NSSelectorFromString("dismissSystemModalTouchBar:")) { NSTouchBar.dismissSystemModalTouchBar(bar) }
    }
    @objc func showPreview() {
        if preview == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 180), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Sway — stato"; window.isReleasedWhenClosed = false
            let label = NSTextField(wrappingLabelWithString: "Sway 0.1 — controlli locali\n\nVolume, display e luce tastiera: tap −/+, swipe continuo, centro volume per muto.\nNessuna telemetria, download di widget o richiesta di amministratore.")
            label.frame = NSRect(x: 24, y: 16, width: 512, height: 140)
            window.contentView?.addSubview(label); window.center(); preview = window
        }
        preview?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func showTailscaleStatus() {
        let alert = NSAlert()
        alert.messageText = "Tailscale"
        let currentFailure = tailscale.lastFailure.map { "\n\($0.message)" } ?? ""
        alert.informativeText = "\(tailscaleButton.toolTip ?? "Stato non disponibile")\(currentFailure)\n\n\(tailscaleLastMessage)\n\nSe l’operazione fallisce, verifica la connessione nell’app Tailscale e comunica questo messaggio completo."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    @objc func toggleTailscale() {
        ControlDiagnostics.record("vpn.action state=\(tailscale.state) busy=\(tailscale.busy)")
        tailscale.toggle()
    }
    func refreshTailscaleButton() {
        ControlDiagnostics.record("vpn.state \(tailscale.state) busy=\(tailscale.busy) failure=\(String(describing: tailscale.lastFailure))")
        tailscaleButton.image = tailscaleIcon(connected: tailscale.state == .connected, busy: tailscale.busy)
        tailscaleButton.isEnabled = !tailscale.busy
        let description: String
        switch tailscale.state {
        case .connected: description = "Tailscale connesso — disconnetti"
        case .disconnected: description = "Tailscale disconnesso — connetti"
        case .starting: description = "Tailscale in connessione"
        case .needsLogin: description = "Tailscale — accesso necessario"
        case .unavailable: description = "Tailscale non installato"
        case .unknown: description = "Tailscale — stato non disponibile"
        }
        tailscaleButton.toolTip = description
        tailscaleButton.setAccessibilityLabel(description)
    }
    func adjustVolume(_ value: Double) {
        audio.setVolume(value)
        if audio.lastError == nil { hud.show(value == 0 ? .muted : .volume, value: value) }
    }
    func toggleMuteWithHUD() {
        audio.toggleMute()
        if audio.lastError == nil, let value = audio.volume { hud.show(audio.muted ? .muted : .volume, value: audio.muted ? 0 : value) }
    }
    func adjustDisplay(_ value: Double) {
        brightness.update(value)
        if brightness.lastError == nil { hud.show(.brightness, value: value) }
    }
    func adjustKeyboard(_ value: Double) {
        keyboardBrightness.update(value)
        if keyboardBrightness.lastError == nil { hud.show(.keyboard, value: value) }
        else if keyboardBrightness.saturated || keyboardBrightness.suppressed { hud.show(.keyboard, value: keyboardBrightness.value ?? 0, locked: true) }
    }
    func showFeedback(_ text: String) {
        lastFeedback = text
        status.button?.toolTip = text
        feedbackMenuItem?.title = text
        barContent.toolTip = text
    }
    @objc func toggleKeyboardAutomatic() {
        let enabled = !keyboardBrightness.automatic
        keyboardBrightness.setAutomatic(enabled)
        if keyboardBrightness.lastError == nil { automaticKeyboardItem.state = enabled ? .on : .off }
        showFeedback(keyboardBrightness.lastError ?? (enabled ? "Tastiera automatica" : "Tastiera manuale"))
    }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        dismiss(); timer?.invalidate(); keyboardBrightness.endInteraction(); hud.cancel(); tailscale.stopMonitoring()
        if let powerSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSource, .defaultMode) }
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer); NotificationCenter.default.removeObserver(observer) }
    }
}
final class AppButton: NSButton {
    var isForeground = false { didSet { needsDisplay = true } }
    let app: NSRunningApplication
    var onError: ((String) -> Void)?
    private var opening = false
    init(app: NSRunningApplication) {
        self.app = app; super.init(frame: NSRect(x: 0, y: 0, width: 36, height: 28))
        let compact = app.icon?.copy() as? NSImage
        compact?.size = NSSize(width: 18, height: 18)
        image = compact; imagePosition = .imageOnly; imageScaling = .scaleNone
        setAccessibilityLabel(app.localizedName ?? "Applicazione"); toolTip = app.localizedName
        target = self; action = #selector(activate); bezelStyle = .rounded; isBordered = false
        widthAnchor.constraint(equalToConstant: 36).isActive = true
        heightAnchor.constraint(equalToConstant: 28).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill(); bounds.fill()
        if isForeground || isHighlighted {
            let shade: CGFloat = isHighlighted ? (isForeground ? 0.75 : 0.25) : 0.9
            NSColor(white: shade, alpha: 1).setFill()
            // Keep the whole rounded highlight inside the hit target and clip viewport.
            NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 2), xRadius: 5, yRadius: 5).fill()
        }
        if let image {
            let rect = NSRect(x: (bounds.width - 18) / 2, y: (bounds.height - 18) / 2, width: 18, height: 18)
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
    }
    @objc func activate() {
        guard !opening else { return }
        guard let url = app.bundleURL else {
            if !app.isTerminated { app.activate(options: []) }
            return
        }
        opening = true
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        // Launch Services sends the application's normal reopen request, as Dock does.
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.opening = false
                if let error { self.onError?("Riapertura: \(error.localizedDescription)") }
            }
        }
    }
}
let app = NSApplication.shared
let delegate = SwayApp()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()

// Vector battery: continuous fill rather than discrete SF Symbol levels.
func batteryIcon(percent: Int?) -> NSImage {
    NSImage(size: NSSize(width: 25, height: 12), flipped: false) { _ in
        let body = NSRect(x: 0.75, y: 0.75, width: 21, height: 10.5)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        let outline = NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2)
        outline.lineWidth = 1.25; outline.stroke()
        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(roundedRect: NSRect(x: 23, y: 4, width: 2, height: 4), xRadius: 0.75, yRadius: 0.75).fill()
        let interior = NSRect(x: 2.5, y: 2.5, width: 17.5, height: 7)
        if let percent {
            let width = interior.width * CGFloat(min(100, max(0, percent))) / 100
            if width > 0 {
                NSGraphicsContext.saveGraphicsState()
                NSBezierPath(roundedRect: interior, xRadius: 1, yRadius: 1).addClip()
                NSColor.white.setFill()
                NSRect(x: interior.minX, y: interior.minY, width: width, height: interior.height).fill()
                NSGraphicsContext.restoreGraphicsState()
            }
        } else {
            NSColor.white.withAlphaComponent(0.5).setFill()
            NSRect(x: 9, y: 5.5, width: 5, height: 1).fill()
        }
        return true
    }
}
