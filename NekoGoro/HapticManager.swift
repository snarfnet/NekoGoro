import CoreHaptics
import UIKit

class HapticManager: ObservableObject {
    private var engine: CHHapticEngine?
    private var purrPlayer: CHHapticPatternPlayer?

    init() { setup() }

    private func setup() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = false
            engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
            try engine?.start()
        } catch { print("Haptic init error: \(error)") }
    }

    func startPurring(intensity: Float = 0.55) {
        guard let engine else { return }
        stopPurring()
        // 25Hz purring: continuous haptic events every 40ms
        var events: [CHHapticEvent] = []
        var t: Double = 0
        while t < 30.0 {
            // Main rumble
            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                ], relativeTime: t, duration: 0.035))
            t += 0.04  // 25Hz
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            purrPlayer = try engine.makePlayer(with: pattern)
            try purrPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch { print("Purr error: \(error)") }
    }

    func stopPurring() {
        try? purrPlayer?.stop(atTime: CHHapticTimeImmediate)
        purrPlayer = nil
    }

    func playMeow() {
        guard let engine else { return }
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ], relativeTime: 0.15)
        ]
        playOnce(events: events)
    }

    func playAngryMeow() {
        guard let engine else { return }
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0)
        ]
        playOnce(events: events)
    }

    private func playOnce(events: [CHHapticEvent]) {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let p = try engine.makePlayer(with: pattern)
            try p.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
