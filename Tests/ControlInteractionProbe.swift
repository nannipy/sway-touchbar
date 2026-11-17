import AppKit

@main struct ControlInteractionProbe {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 80), styleMask: [.titled], backing: .buffered, defer: false)
        var value = 0.5
        var writes: [Double] = []
        var muteCount = 0
        var feedbackCount = 0
        let control = AdjustmentView(symbol: "speaker.wave.2", read: { value }, write: { value = $0; writes.append($0) }, mute: { muteCount += 1 })
        control.frame = NSRect(x: 40, y: 20, width: 140, height: 28)
        window.contentView!.addSubview(control)
        control.feedback = { feedbackCount += 1 }
        control.layoutSubtreeIfNeeded()
        window.makeKeyAndOrderFront(nil)
        application.activate(ignoringOtherApps: true)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        func event(_ type: NSEvent.EventType, _ x: CGFloat) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: control.convert(NSPoint(x: x, y: 14), to: nil), modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
        }
        // Deliver through NSWindow's normal event dispatch, not private gesture helpers.
        window.sendEvent(event(.leftMouseDown, 20))
        window.sendEvent(event(.leftMouseDragged, 55))
        fputs("Drag value: \(value), writes \(writes)\n", stderr)
        assert(abs(value - 0.75) < 0.001, "Drag must update continuously")
        let slider = control.subviews.compactMap { $0 as? NSSlider }.first!
        assert(!slider.isHidden, "Slider must appear during drag")
        assert(control.hitTest(NSPoint(x: control.frame.minX + 70, y: control.frame.midY)) === control, "Visual slider must not steal input")
        window.sendEvent(event(.leftMouseUp, 90))
        assert(value == 1 && writes.count == 2, "Release must commit once, without a trailing tap")
        assert(slider.isHidden)
        assert(feedbackCount == 2)
        // Reversing a gesture still uses its initial value, rather than accumulating deltas.
        value = 0.5; writes.removeAll()
        window.sendEvent(event(.leftMouseDown, 70))
        window.sendEvent(event(.leftMouseDragged, 105))
        window.sendEvent(event(.leftMouseDragged, 35))
        window.sendEvent(event(.leftMouseUp, 35))
        assert(abs(value - 0.25) < 0.001 && muteCount == 0)
        // No move event: AppKit may coalesce a quick swipe into down/up only.
        value = 0.5; writes.removeAll()
        window.sendEvent(event(.leftMouseDown, 20))
        window.sendEvent(event(.leftMouseUp, 55))
        assert(abs(value - 0.75) < 0.001 && writes.count == 1)
        // Ordinary taps and mute remain unchanged.
        value = 0.5; writes.removeAll()
        window.sendEvent(event(.leftMouseDown, 20))
        window.sendEvent(event(.leftMouseUp, 21))
        assert(value == 0.4375 && writes.count == 1)
        window.sendEvent(event(.leftMouseDown, 70))
        window.sendEvent(event(.leftMouseUp, 70))
        assert(muteCount == 1 && writes.count == 1)
        window.sendEvent(event(.leftMouseDown, 120))
        window.sendEvent(event(.leftMouseUp, 120))
        assert(value == 0.5 && writes.count == 2)
        // Layout changes can detach a control before the release arrives.
        window.sendEvent(event(.leftMouseDown, 20))
        window.sendEvent(event(.leftMouseDragged, 55))
        control.removeFromSuperview()
        window.contentView!.addSubview(control)
        value = 0.5; writes.removeAll()
        window.sendEvent(event(.leftMouseDown, 20))
        window.sendEvent(event(.leftMouseUp, 20))
        assert(value == 0.4375 && writes.count == 1, "Interrupted gesture must not latch tracking")
        assert(slider.isAccessibilityHidden())
        // Real Touch Bar event family: allTouches is intentionally empty in the fixture.
        value = 0.5; writes.removeAll()
        control.touchesBegan(with: SwayTestDirectEvent(.began, 20, control))
        control.touchesMoved(with: SwayTestDirectEvent(.moved, 55, control))
        assert(abs(value - 0.75) < 0.001 && !slider.isHidden)
        control.touchesEnded(with: SwayTestDirectEvent(.ended, 90, control))
        assert(value == 1 && writes.count == 2 && slider.isHidden)
        control.touchesBegan(with: SwayTestDirectEvent(.began, 20, control))
        control.touchesEnded(with: SwayTestDirectEvent(.ended, 20, control))
        assert(value == 0.9375 && writes.count == 3, "Direct-touch release must clear tracking")
        control.touchesBegan(with: SwayTestDirectEvent(.began, 20, control))
        control.touchesCancelled(with: SwayTestDirectEvent(.cancelled, 30, control))
        control.touchesBegan(with: SwayTestDirectEvent(.began, 120, control))
        control.touchesEnded(with: SwayTestDirectEvent(.ended, 120, control))
        assert(value == 1 && writes.count == 4)
        print("PASS direct Touch Bar events: drag, release, tap after drag, cancellation recovery")
        window.close()
        print("PASS AppKit dispatch: continuous slider, reversal, coalesced swipe, no trailing tap, mute and tap steps (mock hardware)")
    }
}
