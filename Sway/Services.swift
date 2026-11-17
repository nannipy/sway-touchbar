import AppKit
import CoreAudio
import AudioToolbox
import IOKit.ps
import Darwin

final class AudioService {
    private var device: AudioDeviceID = 0
    private var listeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
    var changed: (() -> Void)?
    private let queue = DispatchQueue.main
    init() {
        observe(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal) { [weak self] in self?.connect() }
        connect()
    }
    deinit { for (id, address, block) in listeners { var a = address; AudioObjectRemovePropertyListenerBlock(id, &a, queue, block) } }
    private func observe(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope, callback: @escaping () -> Void) {
        var a = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        let block: AudioObjectPropertyListenerBlock = { _, _ in callback() }
        if AudioObjectAddPropertyListenerBlock(id, &a, queue, block) == noErr { listeners.append((id, a, block)) }
    }
    private func connect() {
        savedMutedVolume = nil
        for (id, address, block) in listeners where id != AudioObjectID(kAudioObjectSystemObject) { var a = address; AudioObjectRemovePropertyListenerBlock(id, &a, queue, block) }
        listeners.removeAll { $0.0 != AudioObjectID(kAudioObjectSystemObject) }
        var a = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &device) != noErr { device = 0 }
        for selector in [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
            observe(device, selector, kAudioDevicePropertyScopeOutput) { [weak self] in self?.changed?() }
        }
        changed?()
    }
    private func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
    }
    private var volumeAddresses: [AudioObjectPropertyAddress] {
        for selector in [kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyVolumeScalar] {
            var a = address(selector)
            var writable = DarwinBoolean(false)
            if AudioObjectHasProperty(device, &a), AudioObjectIsPropertySettable(device, &a, &writable) == noErr, writable.boolValue { return [a] }
        }
        return (1...2).compactMap { channel in
            var a = address(kAudioDevicePropertyVolumeScalar)
            a.mElement = UInt32(channel)
            var writable = DarwinBoolean(false)
            return AudioObjectHasProperty(device, &a) && AudioObjectIsPropertySettable(device, &a, &writable) == noErr && writable.boolValue ? a : nil
        }
    }
    var volume: Double? {
        let values = volumeAddresses.compactMap { address -> Double? in
            var a = address, value: Float32 = 0
            var size = UInt32(MemoryLayout<Float32>.size)
            guard AudioObjectGetPropertyData(device, &a, 0, nil, &size, &value) == noErr else { return nil }
            return Double(value)
        }
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    private var savedMutedVolume: Double?
    private var muteAddresses: [AudioObjectPropertyAddress] {
        for channels: [UInt32] in [[0], [1, 2]] {
            let addresses = channels.compactMap { channel -> AudioObjectPropertyAddress? in
                var a = address(kAudioDevicePropertyMute); a.mElement = channel
                var writable = DarwinBoolean(false)
                return AudioObjectHasProperty(device, &a) && AudioObjectIsPropertySettable(device, &a, &writable) == noErr && writable.boolValue ? a : nil
            }
            if !addresses.isEmpty { return addresses }
        }
        return []
    }
    var muted: Bool {
        if savedMutedVolume != nil { return true }
        return muteAddresses.contains { address in
            var a = address, value: UInt32 = 0, size: UInt32 = 4
            return AudioObjectGetPropertyData(device, &a, 0, nil, &size, &value) == noErr && value != 0
        }
    }
    private func setMuted(_ muted: Bool) {
        for address in muteAddresses {
            var a = address, value: UInt32 = muted ? 1 : 0
            let result = AudioObjectSetPropertyData(device, &a, 0, nil, 4, &value)
            if result != noErr { lastError = "Muto: errore \(result)" }
        }
    }
    func setVolume(_ value: Double) {
        lastError = nil
        savedMutedVolume = nil
        setMuted(false)
        for address in volumeAddresses {
            var a = address, value = Float32(bounded(value))
            let result = AudioObjectSetPropertyData(device, &a, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
            if result != noErr { lastError = "Audio: errore \(result)" }
        }
        if volumeAddresses.isEmpty { lastError = "Uscita audio non regolabile" }
        changed?()
    }
    private(set) var lastError: String?
    func toggleMute() {
        lastError = nil
        if !muteAddresses.isEmpty { setMuted(!muted) }
        else if let previous = savedMutedVolume { setVolume(previous) }
        else if let previous = volume { setVolume(0); savedMutedVolume = previous }
        else { lastError = "Uscita audio non regolabile" }
        changed?()
    }

}

// Private display adapter: isolated, optional, never invokes a privileged process.
final class BrightnessService {
    typealias Get = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    typealias Set = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private let handle: UnsafeMutableRawPointer?
    private let get: Get?
    private let set: Set?
    typealias CoreGet = @convention(c) (CGDirectDisplayID) -> Double
    typealias CoreSet = @convention(c) (CGDirectDisplayID, Double) -> Void
    private let coreHandle: UnsafeMutableRawPointer?
    private let coreGet: CoreGet?
    private let coreSet: CoreSet?
    init() {
        coreHandle = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY | RTLD_LOCAL)
        coreGet = coreHandle.flatMap { dlsym($0, "CoreDisplay_Display_GetUserBrightness") }.map { unsafeBitCast($0, to: CoreGet.self) }
        coreSet = coreHandle.flatMap { dlsym($0, "CoreDisplay_Display_SetUserBrightness") }.map { unsafeBitCast($0, to: CoreSet.self) }
        handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY | RTLD_LOCAL)
        get = handle.flatMap { dlsym($0, "DisplayServicesGetBrightness") }.map { unsafeBitCast($0, to: Get.self) }
        set = handle.flatMap { dlsym($0, "DisplayServicesSetBrightness") }.map { unsafeBitCast($0, to: Set.self) }
    }
    deinit { if let handle { dlclose(handle) }; if let coreHandle { dlclose(coreHandle) } }
    private var display: CGDirectDisplayID? {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16), count: UInt32 = 0
        guard CGGetOnlineDisplayList(16, &ids, &count) == .success else { return nil }
        return ids.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }
    private var reading: (value: Double, display: CGDirectDisplayID, core: Bool)? {
        guard let display else { return nil }
        // DisplayServices is required on Apple Silicon; CoreDisplay can return a
        // plausible value while writes have no physical effect.
        if let get, set != nil {
            var value: Float = 0
            if get(display, &value) == 0, value.isFinite, (0...1).contains(value) {
                return (Double(value), display, false)
            }
        }
        if let coreGet, coreSet != nil {
            let result = coreGet(display)
            if result.isFinite && (0...1).contains(result) { return (result, display, true) }
        }
        return nil
    }

    var value: Double? { reading?.value }
    private(set) var lastError: String?
    var backend: String { reading.map { $0.core ? "CoreDisplay" : "DisplayServices" } ?? "non disponibile" }
    func update(_ value: Double) {
        lastError = nil
        guard let reading else { lastError = "Luminosità non disponibile"; return }
        if reading.core { coreSet?(reading.display, bounded(value)) }
        else if let set {
            let result = set(reading.display, Float(bounded(value)))
            if result != 0 { lastError = "Luminosità: errore \(result)" }
        }
    }

}

struct BatteryStatus {
    let percent: Int?
    let charging: Bool
}
func batteryStatus() -> BatteryStatus {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return BatteryStatus(percent: nil, charging: false) }
    for source in sources {
        guard let data = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
              data[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
              let current = data[kIOPSCurrentCapacityKey] as? Int,
              let max = data[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
        let charging = data[kIOPSIsChargingKey] as? Bool == true
        return BatteryStatus(percent: Int(bounded(Double(current) / Double(max)) * 100), charging: charging)
    }
    return BatteryStatus(percent: nil, charging: false)
}

// Window metadata only: no titles, images, screen capture or persisted app list.
func windowOwnerPIDs() -> Set<pid_t> {
    guard let windows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
    return Set(windows.compactMap { entry -> pid_t? in
        guard let layer = entry[kCGWindowLayer as String] as? Int,
              let pid = entry[kCGWindowOwnerPID as String] as? Int32,
              let bounds = entry[kCGWindowBounds as String] as? [String: Any],
              let width = bounds["Width"] as? Double, let height = bounds["Height"] as? Double,
              isAppWindow(layer: layer, width: width, height: height, alpha: entry[kCGWindowAlpha as String] as? Double ?? 1) else { return nil }
        return pid
    })
}

final class KeyboardBrightnessService {
    private var originalIdleSuspended: Bool?
    private var idleRestore: DispatchWorkItem?
    func endInteraction() {
        idleRestore?.cancel(); idleRestore = nil
        if let originalIdleSuspended { _ = SwaySetKeyboardIdleSuspended(originalIdleSuspended) }
        originalIdleSuspended = nil
    }
    deinit { endInteraction() }
    var value: Double? {
        let value = SwayKeyboardBrightness()
        return value.isFinite && (0...1).contains(value) ? Double(value) : nil
    }
    private(set) var lastError: String?
    var suppressed: Bool { SwayKeyboardSuppressed() }
    var saturated: Bool { SwayKeyboardSaturated() }
    var automatic: Bool { SwayKeyboardAutomatic() }
    func setAutomatic(_ enabled: Bool) { lastError = SwaySetKeyboardAutomatic(enabled) ? nil : "Modalità tastiera non disponibile" }
    func update(_ value: Double) {
        if saturated && automatic { lastError = "Tastiera: limite luce ambiente"; return }
        if originalIdleSuspended == nil { originalIdleSuspended = SwayKeyboardIdleSuspended() }
        _ = SwaySetKeyboardIdleSuspended(true)
        idleRestore?.cancel()
        let restore = DispatchWorkItem { [weak self] in self?.endInteraction() }
        idleRestore = restore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: restore)
        lastError = SwaySetKeyboardBrightness(Float(bounded(value))) ? nil : "Retroilluminazione tastiera non disponibile"
    }
}
