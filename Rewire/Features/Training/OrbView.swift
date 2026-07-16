import SwiftUI

/// The living rep element — a plasma synapse rendered by the `orb` shader.
/// Purely visual; gestures live in TrainingView. All motion envelopes are
/// derived from timestamps every frame, so charge, hue crossfades and the
/// firing flash are perfectly smooth and interruptible.
struct OrbView: View {
    /// Stage whose color/charge the orb is settling into.
    var stage: RepStage
    /// Stage we are morphing away from.
    var previousStage: RepStage
    /// When the stage last changed (drives charge + hue envelopes).
    var stageChangedAt: Date
    /// When the last rep fired (drives the shockwave/flash), if recent.
    var firedAt: Date?
    /// Per-rep seed so no two taps ever render identically.
    var seed: Double
    /// Long-press swell (cue overlay open).
    var isHolding: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let epoch = Date()
    private static let hueMorphDuration = 0.55
    private static let fireDuration = 1.15

    /// How full the synapse is at each stage — a rep is one charging arc.
    private static func targetCharge(_ stage: RepStage) -> Double {
        switch stage {
        case .trigger: 0.12
        case .notice:  0.40
        case .accept:  0.66
        case .choose:  0.92
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            let now = context.date
            let t = reduceMotion ? 0 : now.timeIntervalSince(Self.epoch)

            let sinceChange = now.timeIntervalSince(stageChangedAt)
            let morph = smooth(clamp(sinceChange / Self.hueMorphDuration))

            let from = Self.targetCharge(previousStage)
            let to = Self.targetCharge(stage)
            // Slight overshoot on the way up makes the charge feel alive.
            let charge = from + (to - from) * overshoot(morph) + (isHolding ? 0.05 : 0)

            let fire: Double = {
                guard let firedAt else { return 0 }
                let x = now.timeIntervalSince(firedAt) / Self.fireDuration
                guard x > 0, x < 1 else { return 0 }
                return 1 - smooth(x)
            }()

            // Opaque fill so the pass is never culled; the shader owns every
            // pixel and returns its own (premultiplied) alpha.
            Rectangle()
                .fill(.white)
                .colorEffect(
                    ShaderLibrary.orb(
                        .float2(CGSize(width: Metrics.orbDiameter, height: Metrics.orbDiameter)),
                        .float(Float(t)),
                        .float(Float(clamp(charge))),
                        .float(Float(morph)),
                        .color(previousStage.color),
                        .color(stage.color),
                        .float(reduceMotion ? 0 : 1),
                        .float(Float(seed.truncatingRemainder(dividingBy: 64))),
                        .float(Float(fire))
                    )
                )
        }
        .frame(width: Metrics.orbDiameter, height: Metrics.orbDiameter)
        .scaleEffect(isHolding ? 1.04 : 1)
        .animation(Springs.scene, value: isHolding)
        .accessibilityLabel("Training orb, stage \(stage.title)")
        .accessibilityAddTraits(.isButton)
    }

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }

    private func smooth(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    /// Ease-out with a gentle overshoot (~4%), settling by 1.
    private func overshoot(_ x: Double) -> Double {
        let c = 1.35
        let p = x - 1
        return 1 + p * p * ((c + 1) * p + c)
    }
}
