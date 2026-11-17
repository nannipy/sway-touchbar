import AppKit
@main struct HardwareProbe {
    static func main() {
        let audio = AudioService(), brightness = BrightnessService(), keyboard = KeyboardBrightnessService()
        print("Volume readable:", audio.volume.map(String.init(describing:)) ?? "unavailable")
        print("Brightness readable:", brightness.value.map(String.init(describing:)) ?? "unavailable")
        if let value = audio.volume, !audio.muted {
            audio.setVolume(value)
            print("Volume write:", audio.lastError ?? "no error", "readback:", audio.volume ?? -1)
        }
        print("Display backend:", brightness.backend)
        print("Keyboard:", keyboard.value ?? -1, "suppressed:", keyboard.suppressed)
        if CommandLine.arguments.contains("--exercise"), let value = brightness.value {
            let requested = value > 0.2 ? value - 0.125 : value + 0.125
            brightness.update(requested)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            print("Display change:", value, "requested:", requested, "readback:", brightness.value ?? -1, "error:", brightness.lastError ?? "none")
            brightness.update(value)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            print("Display restored:", brightness.value ?? -1)
        }
        let originalAutomatic = keyboard.automatic
        if CommandLine.arguments.contains("--manual-keyboard") { keyboard.setAutomatic(false) }
        defer { if CommandLine.arguments.contains("--manual-keyboard") { keyboard.setAutomatic(originalAutomatic) } }
        if CommandLine.arguments.contains("--exercise"), let value = keyboard.value {
            let requested = value > 0.2 ? value - 0.125 : value + 0.125
            keyboard.update(requested)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            print("Keyboard change:", value, "requested:", requested, "readback:", keyboard.value ?? -1, "error:", keyboard.lastError ?? "none")
            keyboard.update(value)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
            print("Keyboard restored:", keyboard.value ?? -1)
        }
        if let value = brightness.value {
            brightness.update(value)
            print("Brightness same-value readback:", brightness.value ?? -1)
        }
        print("Window owner count:", windowOwnerPIDs().count)
    }
}
