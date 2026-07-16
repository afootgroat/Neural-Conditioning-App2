import CoreHaptics
import UIKit

/// One CoreHaptics engine for the whole app, with a named vocabulary of
/// patterns (docs/DESIGN.md §7). Falls back silently on devices without
/// haptics; recovers from engine resets.
@MainActor
final class Haptics {
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {
        guard supported else { return }
        start()
    }

    private func start() {
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.start() }
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard supported, let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Engine may have stopped in the background; try once to revive.
            start()
        }
    }

    private func transient(_ time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    private func continuous(_ time: TimeInterval, duration: TimeInterval,
                            intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time,
            duration: duration
        )
    }

    // MARK: Vocabulary

    /// Each rep stage lands differently under the finger.
    func stage(_ stage: RepStage) {
        switch stage {
        case .trigger:
            // A strike — the old pattern arriving.
            play([transient(0, intensity: 1.0, sharpness: 0.9)])
        case .notice:
            // A bell — sharp onset, ringing decay.
            play(
                [
                    transient(0, intensity: 0.85, sharpness: 0.7),
                    continuous(0.02, duration: 0.3, intensity: 0.5, sharpness: 0.35),
                ],
                curves: [decayCurve(from: 0.5, over: 0.3, startingAt: 0.02)]
            )
        case .accept:
            // An exhale — a soft swell with no edge.
            play(
                [continuous(0, duration: 0.6, intensity: 0.55, sharpness: 0.12)],
                curves: [swellCurve(peak: 0.55, over: 0.6)]
            )
        case .choose:
            // Resolution — two quick rising taps.
            play([
                transient(0, intensity: 0.6, sharpness: 0.5),
                transient(0.09, intensity: 0.9, sharpness: 0.75),
            ])
        }
    }

    /// A completed rep: three-transient rising arpeggio with a soft tail.
    func repFired() {
        play(
            [
                transient(0.00, intensity: 0.7, sharpness: 0.45),
                transient(0.08, intensity: 0.85, sharpness: 0.6),
                transient(0.16, intensity: 1.0, sharpness: 0.85),
                continuous(0.18, duration: 0.35, intensity: 0.35, sharpness: 0.2),
            ],
            curves: [decayCurve(from: 0.35, over: 0.35, startingAt: 0.18)]
        )
    }

    /// Maturity advancement: rumble → beat of silence → bright triple.
    func stageAdvanced() {
        play(
            [
                continuous(0, duration: 0.5, intensity: 0.8, sharpness: 0.15),
                transient(0.72, intensity: 0.8, sharpness: 0.8),
                transient(0.84, intensity: 0.9, sharpness: 0.9),
                transient(0.96, intensity: 1.0, sharpness: 1.0),
            ],
            curves: [decayCurve(from: 0.8, over: 0.5, startingAt: 0)]
        )
    }

    /// Long-press cue overlay.
    func revealOpen() { play([transient(0, intensity: 0.5, sharpness: 0.4)]) }
    func revealClose() { play([transient(0, intensity: 0.3, sharpness: 0.3)]) }

    /// Small confirmations (wizard steps, toggles).
    func tick() { play([transient(0, intensity: 0.4, sharpness: 0.6)]) }

    // MARK: Curves

    private func decayCurve(from peak: Float, over duration: TimeInterval,
                            startingAt start: TimeInterval) -> CHHapticParameterCurve {
        CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: start, value: peak),
                .init(relativeTime: start + duration, value: 0),
            ],
            relativeTime: 0
        )
    }

    private func swellCurve(peak: Float, over duration: TimeInterval) -> CHHapticParameterCurve {
        CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.1),
                .init(relativeTime: duration * 0.55, value: peak),
                .init(relativeTime: duration, value: 0),
            ],
            relativeTime: 0
        )
    }
}
